module Workflow::States
  class BaseState
    def initialize(workflow) = @workflow = workflow

    Workflow::EVENTS.each do |event|
      define_method(event) do |*|
        raise Error::ForbiddenTransition.new(state: @workflow.status, event: event)
      end
    end
  end

  class Created < BaseState
    def start
      @workflow.started!
      @workflow.start_on_swarm_engine
    end
  end

  class Started < BaseState
    def finish(result: nil)
      @workflow.finished!
      @workflow.handle_result(result)
    end

    def stop
      @workflow.stopped!
    end

    def fail
      @workflow.failed!
    end
  end

  class Finished < BaseState
  end

  class Stopped < BaseState
  end

  class Failed < BaseState
  end
end
