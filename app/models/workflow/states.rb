module Workflow::States
  class BaseState
    def initialize(workflow) = @workflow = workflow

    Workflow::ACTIONS.each do |action|
      define_method(action) do |*|
        raise ForbiddenTransition.new(status: @workflow.status, action:)
      end
    end
  end

  class Created < BaseState
    def start
      @workflow.started!
    end
  end

  class Started < BaseState
    def finish
      @workflow.finished!
    end

    def fail
      @workflow.failed!
    end
  end

  class Finished < BaseState
  end

  class Failed < BaseState
  end

  class ForbiddenTransition < StandardError
    def initialize(status:, action:)
      human_status = status.to_s.humanize.downcase
      human_action = action.to_s.humanize.downcase
      super "Can't #{human_action} this workflow because it's #{human_status}."
    end
  end
end
