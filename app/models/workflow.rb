require "aws-sdk-s3"

class Workflow < ApplicationRecord
  STATES = %i[created started finished stopped failed].freeze

  include Uuidable

  belongs_to :workflowable, polymorphic: true

  enum :status, self::STATES.index_with(&:to_s), default: self::STATES.first

  delegate :owner, to: :workflowable
  delegate :project, to: :workflowable
  delegate :make_start_message, to: :workflowable
  delegate :handle_completion, to: :workflowable
  delegate :broadcast_update, to: :project

  after_create :start, if: :created?
  after_update_commit :fetch_peak_ram, if: :just_finished?
  after_update_commit :handle_completion, if: :just_finished?
  after_update_commit :handle_failure, if: :just_failed?
  after_update_commit :broadcast_update, if: :saved_change_to_progress_permil?

  def stop
    SwarmEngine.new.stop_workflow self
  end

  def update_peak_ram!
    peak = bucket.objects(prefix: "projects/#{owner.uuid}/logs/#{uuid}-")
      .filter_map { |summary| peak_ram_in(summary.object.get.body.read) }
      .max

    update! peak_ram_bytes: peak if peak.present?
  end

  def make_stop_message
    { workflow_id: uuid }
  end

  private
    def start
      SwarmEngine.new.start_workflow self
      update! status: :started
    end

    def start_later
      # TODO: Use a background job to start the workflow
    end

    def handle_failure
      project.fail
    end

    def fetch_peak_ram
      FetchWorkflowPeakRamJob.perform_later self
    end

    def just_finished?
      status_previously_changed? && finished?
    end

    def just_failed?
      status_previously_changed? && failed?
    end

    def peak_ram_in(jsonl)
      jsonl.each_line.filter_map do |line|
        JSON.parse(line)["ram"] if line.present?
      rescue JSON::ParserError
        nil
      end.max
    end

    def bucket
      @bucket ||= Aws::S3::Resource.new
        .bucket(Rails.configuration.swarm_engine[:bucket])
    end
end
