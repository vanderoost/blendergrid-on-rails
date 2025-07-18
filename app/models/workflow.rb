class Workflow < ApplicationRecord
  STATES = %i[created open finished stopped failed].freeze
  ACTIONS = %i[start finish fail].freeze

  include Statusable

  belongs_to :workflowable, polymorphic: true
  delegate :project, to: :workflowable

  after_create :start

  def make_start_message
    workflowable.make_workflow_start_message
  end

  def handle_result(result)
    logger.info "Workflow#handle_result"
    return if result.nil?
    logger.debug result.inspect
    workflowable.handle_result(result)
  end
end
