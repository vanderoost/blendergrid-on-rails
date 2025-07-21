module Workflowable
  extend ActiveSupport::Concern

  included do
    has_one :workflow, as: :workflowable
    after_create :create_workflow
    broadcasts_to :project
    delegate :status, to: :workflow
    delegate :settings, to: :workflow

    def make_workflow_message
      raise NotImplementedError
    end
  end
end
