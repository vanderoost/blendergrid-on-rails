class Workflow < ApplicationRecord
  STATES = %i[created started finished stopped failed].freeze
  ACTIONS = %i[start finish stop fail].freeze

  include Statusable
  include Uuidable

  belongs_to :workflowable, polymorphic: true
  delegate :owner, to: :workflowable

  after_create :publish_start

  def make_start_message
    workflowable.make_workflow_start_message
  end

  def handle_result(result)
    # TODO: This is super ugly - FIgure out a better way
    finish
    owner.finish if owner.respond_to? :finish
    return if result.nil?
    workflowable.handle_result(result)
  end

  private
    def publish_start
      start
      SwarmEngine.new.start_workflow self
    end
end
