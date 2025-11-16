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
  after_update_commit :handle_completion, if: :just_finished?
  after_update_commit :handle_failure, if: :just_failed?
  after_update_commit :broadcast_update, if: :saved_change_to_progress_permil?

  def stop
    SwarmEngine.new.stop_workflow self
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

    def just_finished?
      status_previously_changed? && finished?
    end

    def just_failed?
      status_previously_changed? && failed?
    end
end
