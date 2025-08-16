class Workflow < ApplicationRecord
  STATES = %i[created started finished stopped failed].freeze
  EVENTS = %i[start finish stop fail].freeze

  include Statable
  include Uuidable

  belongs_to :workflowable, polymorphic: true

  delegate :owner, to: :workflowable
  delegate :handle_result, to: :workflowable
  delegate :make_start_message, to: :workflowable

  after_create :start

  def start_on_swarm_engine
    SwarmEngine.new.start_workflow self
  end

  def start_on_swarm_engine_later
    # TODO
  end
end
