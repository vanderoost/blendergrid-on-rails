class Workflow < ApplicationRecord
  STATES = %i[created started finished stopped failed].freeze

  include Uuidable

  belongs_to :workflowable, polymorphic: true

  enum :status, self::STATES.index_with(&:to_s), default: self::STATES.first

  delegate :owner, to: :workflowable
  delegate :project, to: :workflowable
  delegate :make_start_message, to: :workflowable
  delegate :handle_completion, to: :workflowable

  after_create :start
  after_update :handle_completion, if: :just_finished?

  def stop
    # TODO
    puts "GOING TO STOP WORKFLOW #{self.uuid}"
  end

  private
    def start
      SwarmEngine.new.start_workflow self
    end

    def start_later
      # TODO
    end

    def just_finished?
      status_previously_changed? && finished?
    end
end
