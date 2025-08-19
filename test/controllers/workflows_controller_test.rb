require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking_project = projects(:checking)
    @blend_check_workflow = @checking_project.blend_check.workflow
    @benchmarking_project = projects(:benchmarking)
    @benchmark_workflow = @benchmarking_project.benchmark.workflow
    @rendering_project = projects(:rendering)
    @render_workflow = @rendering_project.render.workflow
  end

  test "should set status, result, timing, and node type" do
    patch api_v1_workflow_path(@blend_check_workflow), params: {
      workflow: {
        status: "finished",
        result: { "foo" => "fight" },
        timing: { "init" => 134 },
      },
    }, as: :json

    @blend_check_workflow.reload
    assert_equal("finished", @blend_check_workflow.status)
    assert_equal({ "foo" => "fight" }, @blend_check_workflow.result)
    assert_equal({ "init" => 134 }, @blend_check_workflow.timing)
  end

  test "blend check completion should create a settings revision" do
    assert_difference("SettingsRevision.count", 1) do
      patch api_v1_workflow_path(@blend_check_workflow), params: {
        workflow: {
          status: "finished",
          result: { "settings" => { "foo" => "bar" } },
          timing: { "init" => 134 },
        node_provider_id: "aws",
        node_type_name: "t3.micro",
        },
      }, as: :json
    end

    assert_equal("bar", @checking_project.settings.foo)
  end

  test "blend check completion should change the project status to checked" do
    assert @checking_project.checking?, "status should be checking"

    patch api_v1_workflow_path(@blend_check_workflow), params: {
      workflow: {
        status: "finished",
        result: { "settings" => { "foo" => "bar" } },
        timing: { "init" => 134 },
        node_provider_id: "aws",
        node_type_name: "t3.micro",
      },
    }, as: :json

    @checking_project.reload
    assert @checking_project.checked?, "status should be checked"
  end

  test "benchmark completion should change the project status to benchmarked" do
    assert @benchmarking_project.benchmarking?, "status should be benchmarking"

    patch api_v1_workflow_path(@benchmark_workflow), params: {
      workflow: {
        status: "finished",
        result: { "settings" => { "foo" => "bar" } },
        timing: {
          "download" => { "max" => 10000 },
          "init" => { "mean" => 5000, "std" => 1000 },
          "sampling" => { "mean" => 120000, "std" => 10000 },
          "post" => { "mean" => 2000, "std" => 500 },
          "upload" => { "mean" => 3000, "std" => 800 },
        },
        node_provider_id: "aws",
        node_type_name: "t3.micro",
      },
    }, as: :json

    @benchmark_workflow.reload
    assert_equal("aws", @benchmark_workflow.node_provider_id)
    assert_equal("t3.micro", @benchmark_workflow.node_type_name)

    @benchmarking_project.reload
    assert @benchmarking_project.benchmarked?, "status should be benchmarked"
  end

  test "render completion should change the project status to rendered" do
    assert @rendering_project.rendering?, "status should be rendering"

    patch api_v1_workflow_path(@render_workflow), params: {
      workflow: { status: "finished" },
    }, as: :json

    @rendering_project.reload
    assert @rendering_project.rendered?, "status should be rendered"
  end
end
