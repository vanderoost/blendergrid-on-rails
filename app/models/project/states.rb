module Project::States
  class BaseState
    def initialize(project) = @project = project

    Project::ACTIONS.each do |action|
      define_method(action) do |*|
        raise ForbiddenTransition.new(status: @project.status, action:)
      end
    end
  end

  class Uploaded < BaseState
    def start_checking
      @project.checking!
    end
  end

  class Checking < BaseState
    def finish
      @project.checked!
    end

    def fail
      @project.failed!
    end
  end

  class Checked < BaseState
    def start_quoting
      @project.quoting!
    end
  end

  class Quoting < BaseState
    def finish
      @project.quoted!
    end

    def fail
      @project.failed!
    end
  end

  class Quoted < BaseState
    def start_rendering
      @project.rendering!
    end
  end

  class Rendering < BaseState
    def finish
      @project.rendered!
    end

    def cancel
      @project.cancelled!
    end

    def fail
      @project.failed!
    end
  end

  class Rendered < BaseState
  end

  class Finished < BaseState
  end

  class Cancelled < BaseState
  end

  class Failed < BaseState
  end

  class ForbiddenTransition < StandardError
    def initialize(status:, action:)
      human_status = status.to_s.humanize.downcase
      human_action = action.to_s.humanize.downcase
      super "Can't #{human_action} this project because it's #{human_status}."
    end
  end
end
