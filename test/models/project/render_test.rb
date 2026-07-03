require "test_helper"

class Project::RenderTest < ActiveSupport::TestCase
  setup do
    @render = project_renders(:active)
    @project = @render.project
    @project.define_singleton_method(:job_time) { 2.minutes }
  end

  test "render execution requires device and ram for GPU with known peak RAM" do
    @project.define_singleton_method(:render_with_gpu?) { true }
    create_benchmark_with_peak_ram 188596224

    execution = @render.send(:render_execution, "test-execution-id")

    assert_equal({ device: "GPU", ram: 188596224 }, execution[:requirements])
  end

  test "render execution requires ram for CPU renders too" do
    @project.define_singleton_method(:render_with_gpu?) { false }
    create_benchmark_with_peak_ram 140668928

    execution = @render.send(:render_execution, "test-execution-id")

    assert_equal({ ram: 140668928 }, execution[:requirements])
  end

  test "render execution omits ram when no peak RAM was measured" do
    @project.define_singleton_method(:render_with_gpu?) { false }

    execution = @render.send(:render_execution, "test-execution-id")

    assert_equal({}, execution[:requirements])
  end

  private
    def create_benchmark_with_peak_ram(bytes)
      benchmark = @project.benchmarks.create!
      benchmark.workflow.update! peak_ram_bytes: bytes
    end
end
