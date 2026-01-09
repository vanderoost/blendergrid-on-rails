require "aws-sdk-s3"

class Project < ApplicationRecord
  STATES = %i[ created checking checked benchmarking benchmarked rendering rendered
    cancelled failed ].freeze
  EVENTS = %i[ start_checking start_benchmarking start_rendering finish_checking
    finish_benchmarking finish_rendering cancel fail ].freeze
  STAGES = %i[ uploaded waiting rendering finished stopped ].freeze
  STORE_ACCESSORS = {
    tweaks: {
      deadline_hours: :integer,
      deadline_hours_min: :integer,
      deadline_hours_max: :integer,
      resolution_percentage: :integer,
      sampling_max_samples: :integer,
    },
  }
  DEFAULT_DEADLINE_HOURS = 5

  include HasSceneSettings
  include JsonAccessible
  include Statable
  include Uuidable

  belongs_to :upload
  has_many :order_items, class_name: "Order::Item"
  has_many :orders, through: :order_items
  has_many :blend_checks, class_name: "Project::BlendCheck"
  has_many :benchmarks, class_name: "Project::Benchmark"
  has_many :renders, class_name: "Project::Render"

  delegate :user, to: :upload

  before_save :update_stage_timestamp, if: :stage_changed? || stage_updated_at.nil?
  after_create :start_checking, if: :created?
  before_create :set_name
  before_update :update_price, if: :tweaks_changed?
  after_update_commit :broadcast, if: :saved_change_to_status?

  validates :blend_filepath, presence: true

  default_scope { where(deleted_at: nil)
    .where(updated_at: 30.days.ago..)
    .order(stage_updated_at: :desc) }

  def self.in_stages
    all.group_by(&:stage).map { |stage, projects| stage.new(projects) }.sort_by(&:order)
  end

  def in_progress?
    %w[created checking benchmarking rendering].include? status
  end

  def order_item
    @order_item ||= (association(:order_items).loaded? ?
      order_items.max_by { |oi| oi.order&.id || 0 } :
      order_items.joins(:order).order("orders.id DESC").first)
  end

  def order
    @order ||= (association(:order_items).loaded? ?
      order_items.map(&:order).compact.max_by(&:id) :
      orders.order(id: :desc).first)
  end

  def to_key
    [ uuid ]
  end

  def stage
    status_to_stage status
  end

  def blender_version
    full_version = blend_check&.workflow&.result&.dig(
      "stats", "blender_version", "saved"
    )
    if full_version
      full_version.split(".").first(2).join(".")
    else
      "latest"
    end
  end

  def ffmpeg_extension
    current_blender_scene&.output_ffmpeg_format&.extension
  end

  def process_blend_check
    workflow = blend_check.workflow
    raise "Project has no BlendCheck Workflow" if workflow.blank?

    scenes_data = workflow.result&.dig("settings", "scenes")
    raise "Missing scenes data" if scenes_data.blank?

    current_scene_name = workflow.result&.dig("settings", "scene_name")
    scenes_data&.each do |scene_name, settings|
      blender_scene = blender_scenes.find_or_initialize_by(name: scene_name)
      blender_scene.update(settings.slice(*BlenderScene.column_names))
      self.current_blender_scene = blender_scene if scene_name == current_scene_name
    end
  end

  def process_benchmark
    raise "Project has no BlenderScene" if current_blender_scene.blank?

    self.tweaks_deadline_hours = Project::DEFAULT_DEADLINE_HOURS
    self.tweaks_resolution_percentage = resolution_percentage
    self.tweaks_sampling_max_samples = sampling_max_samples

    update_price

    self.save!
  end

  def frame_objects
    @frame_objects ||= begin
      prefix = "projects/#{uuid}/frames/"
      objects = bucket.objects(prefix: prefix).sort_by(&:key).map do |obj|
        filename = obj.key.split("/").last
        extension = File.extname(filename)
        basename = File.basename(filename, extension)
        frame_number = basename.scan(/\d{4,}/).last&.to_i || 0
        {
          frame_number: frame_number,
          basename: basename,
          extension: extension,
          size: obj.size,
          url: Rails.env.production? ?
            "https://#{bucket_name}.s3.us-east-1.amazonaws.com/#{obj.key}" :
            obj.presigned_url(:get, expires_in: 1.hour.in_seconds),
        }
      end
      objects
    end
  end

  def sample_frame_urls
    prefix = "projects/#{uuid}/sample-frames/"
    bucket.objects(prefix: prefix)
      .sort_by(&:key)
      .map { |obj| obj.presigned_url(:get, expires_in: 1.hour.in_seconds) }
  end

  def output_objects
    prefix = "projects/#{uuid}/output/"
    @output_objects ||= bucket.objects(prefix: prefix).sort_by(&:key).map do |obj|
      filename = obj.key.split("/").last
      extension = File.extname(filename)
      {
        basename: File.basename(filename, extension),
        extension: extension,
        size: obj.size,
        url: obj.presigned_url(
          :get, expires_in: 1.hour.in_seconds,
          use_accelerate_endpoint: Rails.env.production?
        ),
      }
    end
  end

  def download_link
    if output_objects.one?
      output_objects.first[:url]
    elsif frame_objects.one?
      frame_objects.first[:url]
    else
      nil
    end
  end

  def owner
    @owner ||= if user.present?
      user.name || user.email_address
    else
      "guest #{upload.guest_email_address}"
    end
  end

  def bucket
    @bucket ||= s3.bucket(bucket_name)
  end

  def bucket_name
    @bucket_name ||= Rails.configuration.swarm_engine[:bucket]
  end

  def s3
    @s3 ||= Aws::S3::Resource.new
  end

  def handle_cancellation
    workflow = render.workflow
    workflow.stop
    partial_refund workflow.progress_permil
  end

  def blend_check = latest(:blend_check)
  def benchmark = latest(:benchmark)
  def render = latest(:render)

  def broadcast
    if saved_change_to_stage?
      broadcast_remove_to broadcast_channel
      broadcast_prepend_to broadcast_channel, target: "#{stage}-projects"
    else
      broadcast_update
    end
  end

  def broadcast_update
      broadcast_replace_to broadcast_channel
  end

  def warnings
    Hash(blend_check&.workflow&.result&.dig(
        "stats", "warnings", "scenes", current_blender_scene.name
    ))
  end

  def update_price
    self.tweaks_deadline_hours_min = price_calculation.deadline_hours_min
    self.tweaks_deadline_hours_max = price_calculation.deadline_hours_max
    if self.tweaks_deadline_hours < self.tweaks_deadline_hours_min
      self.tweaks_deadline_hours = self.tweaks_deadline_hours_min
    elsif self.tweaks_deadline_hours > self.tweaks_deadline_hours_max
      self.tweaks_deadline_hours = self.tweaks_deadline_hours_max
    end

    self.price_cents = price_calculation.price_cents
  end

  private
    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end

    def set_name
      return if name.present?
      self.name = File.basename(blend_filepath, ".blend")
    end

    def broadcast_channel
      @broadcast_channel ||= [ upload.user_id || upload.guest_session_id, :projects ]
    end

    def update_stage_timestamp
      self.stage_updated_at = Time.current
    end

    def stage_changed?
      return false unless status_changed?
      status_to_stage(status_was) != stage
    end

    def price_calculation
      @price_calculation ||= Pricing::Calculation.new(
        benchmark: benchmark,
        node_supplies: NodeSupply.where(
          provider_id: benchmark.workflow.node_provider_id,
          type_name: benchmark.workflow.node_type_name
        ),
        blender_scene: current_blender_scene,
        tweaks: tweaks,
      )
    end

    def saved_change_to_stage?
      status_to_stage(status_before_last_save) != stage
    end

    def partial_refund(permil)
      permil ||= 0
      permil_to_refund = 1000 - permil
      refund_cents = price_cents * permil_to_refund.fdiv(1000)

      unless refund_cents.positive?
        puts "REFUND IS NOT POSITIVE (#{refund_cents} cents)"
        return
      end

      # puts "REFUNDING #{permil_to_refund.fdiv(10)}% OF $#{refund_cents.fdiv(100)} ="\
      #   " $#{refund_cents.fdiv(100)}"

      # What we want to do is:
      # - If the project has a registered user, top up their credit. Set a timer for the
      # real refund to happen. If they use the credit, cancel the real refund.
      # - If the project doesn't have a registered user, refund the Strip transaction
      # directly.

      # Create a Refund
      refund = Refund.create(
        order_item: order_item,
        amount_cents: refund_cents,
      )

      if user.present?
        # Figure out the ratio of credit / cash that was paid (from Order)
        cash_refund = order_item.cash_cents * permil_to_refund.fdiv(1000)
        credit_refund = refund.amount_cents - cash_refund

        # Immediately refund the credit
        if credit_refund.positive?
          refund.credit_entries.create(
            user: user,
            amount_cents: credit_refund,
            reason: :credit_refund,
          )
        end

        # Temporarily refund the cash as credit
        if cash_refund.positive?
          refund.credit_entries.create(
            user: user,
            amount_cents: cash_refund,
            reason: :delayed_cash_refund,
          )
        end
      else

        # Figure out the Stripe transaction from the Order
        # Refund the amount from the Stripe transaction

      end

      # First refund in Render credit only.
      # After a timeout, and the credit hasn't been used, do a full refund.
    end
end

def status_to_stage(status)
  case status&.to_sym
  when :created, :checking, :checked then :uploaded
  when :benchmarking, :benchmarked then :waiting
  when :rendering then :rendering
  when :rendered then :finished
  when :cancelled, :failed then :stopped
  end
end
