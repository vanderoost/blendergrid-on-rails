class FetchWorkflowPeakRamJob < ApplicationJob
  queue_as :default

  def perform(workflow)
    workflow.update_peak_ram!
  end
end
