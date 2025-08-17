class Workflow < ApplicationRecord
  STATES = %i[created started finished stopped failed].freeze

  include Uuidable

  belongs_to :workflowable, polymorphic: true

  enum :status, self::STATES.index_with(&:to_s), default: self::STATES.first

  delegate :owner, to: :workflowable
  delegate :handle_result, to: :workflowable
  delegate :make_start_message, to: :workflowable

  after_create :start

  def start
    SwarmEngine.new.start_workflow self
  end

  def start_later
    # TODO
  end
end
