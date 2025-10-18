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
      resolution_percentage: :integer,
      sampling_max_samples: :integer,
    },
  }

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

  after_create :start_checking
  before_update :update_price, if: :tweaks_changed?
  after_update_commit :broadcast, if: :saved_change_to_status?

  validates :blend_filepath, presence: true

  def self.in_stages
    all.group_by(&:stage).map { |stage, projects| stage.new(projects) }.sort_by(&:order)
  end

  def in_progress?
    %w[created checking benchmarking rendering].include? status
  end


  def to_key
    [ uuid ]
  end

  def name
    blend_filepath
  end

  def stage
    status_to_stage status
  end

  def process_benchmark
    raise "Project has no BlenderScene" if current_blender_scene.blank?

    # TODO: Choose a sensible deadline based on the benchmark / exp. server hours
    self.tweaks_deadline_hours = 8
    self.tweaks_resolution_percentage = resolution_percentage
    self.tweaks_sampling_max_samples = sampling_max_samples

    # Initialize the price
    update_price

    self.save!
  end

  def frame_urls
    bucket_name = Rails.configuration.swarm_engine[:bucket]
    prefix = "projects/#{uuid}/output/frames/"
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(bucket_name)
    bucket.objects(prefix: prefix)
      .sort_by(&:key)
      .map { |obj| obj.presigned_url(:get, expires_in: 1.hour.in_seconds) }
  end

  def handle_cancellation
    render.workflow.stop
    partial_refund render.workflow.progress_permil
  end

  def blend_check = latest(:blend_check)
  def benchmark = latest(:benchmark)
  def render = latest(:render)

  private
    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end

    def broadcast
      if saved_change_to_stage?
        broadcast_remove_to :projects
        broadcast_prepend_to :projects, target: "#{stage}-projects"
      else
        broadcast_replace_to :projects
      end
    end

    def update_price
      workflow = benchmark.workflow
      self.price_cents = Pricing::Calculation.new(
        benchmark: benchmark,
        node_supplies: NodeSupply.where(
          provider_id: workflow.node_provider_id, type_name: workflow.node_type_name
        ),
        blender_scene: current_blender_scene,
        tweaks: tweaks,
      ).price_cents
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
  case status.to_sym
  when :created, :checking, :checked then :uploaded
  when :benchmarking, :benchmarked then :waiting
  when :rendering then :rendering
  when :rendered then :finished
  when :cancelled, :failed then :stopped
  end
end
