class FetchWorkflowPeakRamJob < ApplicationJob
  queue_as :default

  def perform(workflow)
    # Benchmark workflows fetch their peak RAM synchronously during pricing,
    # so by the time this job runs there is usually nothing left to do.
    return if workflow.peak_ram_bytes.present?

    workflow.update_peak_ram!
  end
end
