module Project::States
  ACTIONS = [
    :start_price_calculation, :start_render, :finish, :cancel, :fail
  ].freeze

  class BaseState
    def initialize(project)
      @project = project
    end

    ACTIONS.each do |action|
      define_method(action) do |*|
        raise InvalidTransition.new(status: @project.status, action: action)
      end
    end
  end

  class Uploaded < BaseState
    def check_integrity
      Workflows::StartIntegrityCheckJob.perform_later(@project)

      @project.update!(status: :checking_integrity)
    end
  end

  class CheckingIntegrity < BaseState
    def finish(result: nil)
      if result
        if result[:settings]
          @project.settings = result[:settings]
        end
        if result[:stats]
          @project.stats = result[:stats]
        end
      end

      @project.update!(status: :integrity_checked)
    end
  end

  class IntegrityChecked < BaseState
    def calculate_price
      Rails.logger.info "Starting price calculation for project #{@project.name}"

      Workflows::StartPriceCalculationJob.perform_later(@project)

      @project.update!(status: :calculating_price)
    end
  end

  class CalculatingPrice < BaseState
    def finish(result: nil)
      @project.update!(status: :price_calculated)

      # ProjectMailer.with(project: @project).price_calculated.deliver_later
    end

    def fail
      @project.update!(status: :failed)
    end
  end

  class PriceCalculated < BaseState
    def start_render
      # Workflows::StartRenderJob.perform_later(@project)

      @project.update!(status: :rendering)
    end
  end

  class Rendering < BaseState
    def finish(result: nil)
      @project.update!(status: :finished)

      # ProjectMailer.with(project: @project).render_finished.deliver_later
    end

    def cancel
      # Workflows::StopRenderJob.perform_later(@project)

      @project.update!(status: :cancelled)
    end

    def fail
      @project.update!(status: :failed)

      # ProjectMailer.with(project: @project).render_failed.deliver_later
    end
  end

  class Finished < BaseState
  end

  class Cancelled < BaseState
  end

  class Failed < BaseState
  end

  class InvalidTransition < StandardError
    def initialize(status:, action:)
      status_str = status.to_s.humanize.downcase
      action_str = action.to_s.humanize.downcase

      super "Can't #{action_str} when it's #{status_str}."
    end
  end
end
