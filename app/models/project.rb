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
  belongs_to :order, optional: true
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

  default_scope { order(stage_updated_at: :desc) }

  def self.in_stages
    all.group_by(&:stage).map { |stage, projects| stage.new(projects) }.sort_by(&:order)
  end

  def in_progress?
    %w[created checking benchmarking rendering].include? status
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

  def process_benchmark
    raise "Project has no BlenderScene" if current_blender_scene.blank?

    # TODO: Choose a sensible deadline based on the benchmark / exp. server hours
    self.tweaks_deadline_hours = Project::DEFAULT_DEADLINE_HOURS
    self.tweaks_resolution_percentage = resolution_percentage
    self.tweaks_sampling_max_samples = sampling_max_samples

    # Initialize the price
    update_price

    self.save!
  end

  # TODO: Maybe deprecate this and use frame_objects
  def frame_urls
    prefix = "projects/#{uuid}/output/frames/"
    bucket.objects(prefix: prefix)
      .sort_by(&:key)
      .map { |obj| obj.presigned_url(:get, expires_in: 1.hour.in_seconds) }
  end

  def frame_objects
    prefix = "projects/#{uuid}/frames/"
    objects = bucket.objects(prefix: prefix).sort_by(&:key).map do |obj|
      filename = obj.key.split("/").last
      extension = File.extname(filename)
      {
        basename: File.basename(filename, extension),
        extension: extension,
        size: obj.size,
        url: obj.presigned_url(:get, expires_in: 1.hour.in_seconds),
      }
    end
    puts "FRAME OBJECT: #{objects.first.inspect}"
    objects
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
        url: obj.presigned_url(:get, expires_in: 1.hour.in_seconds),
      }
    end
  end

  def download_link
    if output_objects.blank?
      nil
    elsif output_objects.one?
      output_objects.first[:url]
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
    render.workflow.stop
    partial_refund render.workflow.progress_permil
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

    # TODO: Refactor to a "refundable" concern
    def partial_refund(permil)
      permil ||= 0
      permil_to_refund = 1000 - permil
      refund_cents = price_cents * permil_to_refund.fdiv(1000)
      # puts "REFUNDING #{permil_to_refund.fdiv(10)}% OF $#{refund_cents.fdiv(100)} ="\
      #   " $#{refund_cents.fdiv(100)}"

      if refund_cents.positive? and user.present?
        puts "TOPPING UP CREDIT"
        user.update(render_credit_cents: user.render_credit_cents + refund_cents)
      else
        # puts "NO USER ASSOCIATED"
        # TODO: Figure out how to handle the refund wihtout a user
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
