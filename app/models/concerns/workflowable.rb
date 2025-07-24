module Workflowable
  extend ActiveSupport::Concern

  included do
    belongs_to :project
    has_one :workflow, as: :workflowable
    after_create :start_workflow
    delegate :status, to: :workflow
    delegate :settings, to: :workflow

    # broadcasts_to :project

    def make_workflow_message
      raise NotImplementedError
    end
  end
end
