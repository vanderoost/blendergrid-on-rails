module Project::States
  class BaseState
    def initialize(project) = @project = project

    Project::EVENTS.each do |event|
      define_method(event) do |*|
        raise Error::ForbiddenTransition.new(state: @project.status, event: event)
      end
    end
  end

  class Created < BaseState
    def start_checking
      @project.checking!
      @project.fail unless @project.blend_checks.create
    end
  end

  class Checking < BaseState
    def finish_checking
      @project.checked!
    end

    def fail
      @project.failed!
    end
  end

  class Checked < BaseState
    def start_benchmarking
      @project.benchmarking!
    end
  end

  class Benchmarking < BaseState
    def finish_benchmarking
      @project.benchmarked!
    end

    def fail
      @project.failed!
    end
  end

  class Benchmarked < BaseState
    def start_rendering
      @project.rendering!
    end
  end

  class Rendering < BaseState
    def finish_rendering
      @project.rendered!
    end

    def cancel
      @project.cancelled!
    end

    def fail
      @project.failed!
      # TODO: Here we should send an email to the user
    end
  end

  class Rendered < BaseState
  end

  class Cancelled < BaseState
  end

  class Failed < BaseState
  end
end
