require "test_helper"

class Project::BenchmarkTest < ActiveSupport::TestCase
  test "sample settings are set after creation" do
    project = projects(:checked)
    settings = {}

    benchmark = project.benchmarks.create(settings: settings)

    assert benchmark.sample_settings.present?
  end
end
