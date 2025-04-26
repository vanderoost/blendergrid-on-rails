# TODO: Consider splitting up in multiple files but keep it simple for now
module ProjectStates
  class BaseState
    def initialize(project)
      @project = project
    end

    def start_integrity_check
      raise "Can't #{__method__} in state '#{@project.status}'"
    end

    def start_price_calculation
      raise "Can't #{__method__} in state '#{@project.status}'"
    end

    def start_render
      raise "Can't #{__method__} in state '#{@project.status}'"
    end

    def finish
      raise "Can't #{__method__} in state '#{@project.status}'"
    end

    def cancel
      raise "Can't #{__method__} in state '#{@project.status}'"
    end

    def fail
      raise "Can't #{__method__} in state '#{@project.status}'"
    end

    def delete
      raise "Can't #{__method__} in state '#{@project.status}'"
    end
  end

  class ProjectStates::Uploaded < ProjectStates::BaseState
    def start_integrity_check
      puts "Starting integrity check!"

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
