module Workflowable
  extend ActiveSupport::Concern

  included do
    include Trackable

    has_one :workflow, as: :workflowable
    after_create :create_workflow
    delegate :status, to: :workflow

    def make_start_message
      raise NotImplementedError
    end
  end
end
