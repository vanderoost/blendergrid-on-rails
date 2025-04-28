# TODO: Consider splitting up in multiple files but keep it simple for now
module ProjectStates
  class BaseState
    ACTIONS = %i[
        check_integrity
        calculate_price
        start_render
        finish
        cancel
        fail
        delete
      ].freeze

    def initialize(project)
      @project = project
    end

    ACTIONS.each do |event|
      define_method(event) do |*|
        raise "Can't #{event} in state '#{@project.status}'"
      end
    end
  end

  class Uploaded < BaseState
    def check_integrity
      workflow = @project.workflows.create!(
        uuid: SecureRandom.uuid,
        job_type: :integrity_check
      )

      Workflows::StartIntegrityCheckJob.perform_later(workflow.id)

      @project.update!(status: :checking_integrity)
    end
  end

  class CheckingIntegrity < BaseState
    def finish(result: nil)
      puts "Integrity check finished!"

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

      workflow = @project.workflows.create!(
        uuid: SecureRandom.uuid,
        job_type: :price_calculation
      )

      Workflows::StartPriceCalculationJob.perform_later(workflow.id)

      @project.update!(status: :calculating_price)
    end
  end

  class CalculatingPrice < BaseState
  end

  class PriceCalculated < BaseState
  end

  class Rendering < BaseState
  end

  class Finished < BaseState
  end

  class Cancelled < BaseState
  end

  class Failed < BaseState
  end

  class Deleted < BaseState
  end
end
