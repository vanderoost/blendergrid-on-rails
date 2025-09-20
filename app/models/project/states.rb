module Project::States
  class BaseState
    def initialize(project)
      @project = project
    end

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
    def start_benchmarking(settings:)
      @project.benchmarking!
      @project.fail unless @project.benchmarks.create(settings: settings)
    end
  end

  class Benchmarking < BaseState
    def finish_benchmarking
      @project.benchmarked!
      @project.benchmark.calculate_price
    end

    def fail
      @project.failed!
    end
  end

  class Benchmarked < BaseState
    def start_rendering
      @project.rendering!
      @project.fail unless @project.renders.create
    end
  end

  class Rendering < BaseState
    def finish_rendering
      @project.rendered!
      ProjectMailer.project_render_finished(@project).deliver_later
    end

    def cancel
      @project.cancelled!
      @project.handle_cancellation
    end

    def fail
      @project.failed!
    end
  end

  class Rendered < BaseState
  end

  class Cancelled < BaseState
  end

  class Failed < BaseState
  end
end
