require "aws-sdk-s3"

class Project < ApplicationRecord
  STATES = %i[ created checking checked benchmarking benchmarked rendering rendered
    cancelled failed ].freeze
  EVENTS = %i[ start_checking start_benchmarking start_rendering finish_checking
    finish_benchmarking finish_rendering cancel fail ].freeze
  STAGES = %i[ uploaded waiting rendering finished stopped ].freeze

  include Statable
  include Uuidable
  include HasSceneSettings

  belongs_to :upload
  has_many :blend_checks, class_name: "Project::BlendCheck"
  has_many :benchmarks, class_name: "Project::Benchmark"
  has_many :renders, class_name: "Project::Render"
  has_one :order_item, class_name: "Order::Item"

  delegate :user, to: :upload
  delegate :order, to: :order_item, allow_nil: true

  after_create :start_checking
  after_update_commit :maybe_broadcast

  validates :blend_filepath, presence: true

  def self.in_stages
    all.group_by(&:stage).map { |stage, projects| stage.new(projects) }.sort_by(&:order)
  end

  def in_progress?
    %w[created checking benchmarking rendering].include?(status)
  end

  def name
    blend_filepath
  end

  def stage
    status_to_stage status
  end

  def price_cents(tweaks = {})
    raise "Project has no BlenderScene" if current_blender_scene.blank?

    workflow = benchmark.workflow
    Pricing::Calculation.new(
      benchmark: benchmark,
      node_supplies: NodeSupply.where(
        provider_id: workflow.node_provider_id, type_name: workflow.node_type_name
      ),
      blender_scene: current_blender_scene,
      tweaks: tweaks,
    ).price_cents
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
    order_item.partial_refund render.workflow.progress_permil if order_item.present?
  end

  def blend_check = latest(:blend_check)
  def benchmark = latest(:benchmark)
  def render = latest(:render)

  private
    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end

    def maybe_broadcast
      return unless saved_change_to_status?

      puts "PORJECT STATUS CHANGED: #{status_before_last_save} -> #{status}"
      stage_before_last_save = status_to_stage status_before_last_save

      target = "#{stage}-projects"
      partial = "projects/project"
      locals = { project: self }

      if stage_before_last_save != stage
        puts "STAGE CHANGED: #{stage_before_last_save} -> #{stage}"

        puts "BROADCASTING REMOVE"
        broadcast_remove_to :projects

        puts "BROADCASTING APPEND"
        broadcast_append_to :projects, target:, partial:, locals:
      else
        puts "BROADCASTING REPLACE"
        broadcast_replace_to :projects, target:, partial:, locals:
      end
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
