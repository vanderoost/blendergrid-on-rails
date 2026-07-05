module Workflowable
  extend ActiveSupport::Concern

  included do
    include Trackable

    has_one :workflow, as: :workflowable
    # Check the target without loading the association: a cached nil would
    # still be visible when Workflow#start reads `workflow` mid-create.
    after_create :create_workflow, if: -> { association(:workflow).target.blank? }
    delegate :status, to: :workflow

    def make_start_message
      raise NotImplementedError
    end

    def ongoing?
      [ :created, :started ].include? status.to_sym
    end
  end
end
