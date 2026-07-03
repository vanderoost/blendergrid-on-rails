require "test_helper"

class WorkflowTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "finishing any workflow enqueues a job to fetch its peak RAM" do
    workflow = workflows(:started_render)

    assert_enqueued_with(job: FetchWorkflowPeakRamJob, args: [ workflow ]) do
      workflow.update! status: :finished
    end
  end

  test "update_peak_ram! stores the max ram across all stats log files" do
    workflow = workflows(:finished_benchmark)
    prefix = "projects/#{workflow.project.uuid}/logs/#{workflow.uuid}"
    bodies = {
      "#{prefix}-execution-1-0.json" => <<~JSONL,
        {"time":1783078133177,"cpu":0.0,"ram":9838592}
        {"time":1783078134187,"cpu":74.7,"ram":140668928}

      JSONL
      "#{prefix}-execution-1-1.json" => <<~JSONL,
        {"time":1783078135195,"cpu":91.3,"ram":175190016}
        {"time":1783078136203,"cpu":80.8,"ram":188596224}
        {"time":178307813
      JSONL
    }

    client = workflow.project.bucket.client
    client.stub_responses(:list_objects_v2, {
      contents: bodies.keys.map { |key| { key: key } },
    })
    client.stub_responses(:get_object, ->(context) {
      { body: bodies.fetch(context.params[:key]) }
    })

    workflow.update_peak_ram!

    assert_equal 188596224, workflow.reload.peak_ram_bytes
  end

  test "update_peak_ram! leaves peak_ram_bytes nil when no stats logs exist" do
    workflow = workflows(:finished_benchmark)

    workflow.update_peak_ram!

    assert_nil workflow.reload.peak_ram_bytes
  end
end
