module Workflowable
  extend ActiveSupport::Concern

  included do
    has_one :workflow, as: :workflowable
    after_create :add_workflow

    def add_workflow
      create_workflow(uuid: SecureRandom.uuid)
    end

    def make_workflow_message
      raise NotImplementedError
    end
  end
end
