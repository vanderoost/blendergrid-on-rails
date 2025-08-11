module Workflowable
  extend ActiveSupport::Concern

  included do
    has_one :workflow, as: :workflowable
    after_create :start_workflow
    delegate :status, to: :workflow

    def make_workflow_start_message
      raise NotImplementedError
    end
  end
end
