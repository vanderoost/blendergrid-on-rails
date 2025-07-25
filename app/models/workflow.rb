class Workflow < ApplicationRecord
  STATES = %i[created started finished stopped failed].freeze
  ACTIONS = %i[start finish stop fail].freeze

  include Statusable
  include Uuidable

  belongs_to :workflowable, polymorphic: true
  delegate :project, to: :workflowable

  after_create :publish_start

  def make_start_message
    workflowable.make_workflow_start_message
  end

  def handle_result(result)
    finish
    project.finish
    return if result.nil?
    workflowable.handle_result(result)
  end

  private
    def publish_start
      start
      SwarmEngine.new.start_workflow self
    end
end
