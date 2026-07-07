require "test_helper"

class FetchWorkflowPeakRamJobTest < ActiveJob::TestCase
  test "fetches the peak RAM when it is not known yet" do
    workflow = workflows(:finished_benchmark)
    assert_nil workflow.peak_ram_bytes

    Aws.config[:s3] = { stub_responses: {
      list_objects_v2: { contents: [ { key: "stats-log.json" } ] },
      get_object: { body: '{"time":1783078135195,"cpu":91.3,"ram":188596224}' },
    } }

    FetchWorkflowPeakRamJob.perform_now workflow

    assert_equal 188596224, workflow.reload.peak_ram_bytes
  ensure
    Aws.config.delete(:s3)
  end

  test "skips the S3 fetch when the peak RAM is already known" do
    workflow = workflows(:finished_benchmark)
    workflow.update! peak_ram_bytes: 123456789

    Aws.config[:s3] = { stub_responses: {
      list_objects_v2: { contents: [ { key: "stats-log.json" } ] },
      get_object: { body: '{"time":1783078135195,"cpu":91.3,"ram":188596224}' },
    } }

    FetchWorkflowPeakRamJob.perform_now workflow

    assert_equal 123456789, workflow.reload.peak_ram_bytes
  ensure
    Aws.config.delete(:s3)
  end
end
