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

    def ongoing?
      [ :created, :started ].include? status.to_sym
    end
  end
end
