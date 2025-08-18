require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:checking)
    @blend_check_workflow = @project.blend_check.workflow
  end

  test "should set status, result, timing, and node type" do
    patch api_v1_workflow_path(@blend_check_workflow), params: {
      workflow: {
        status: "finished",
        result: { "foo" => "fight" },
        timing: { "init" => 134 },
        node_type: "aws_t3.micro",
      },
    }, as: :json

    @blend_check_workflow.reload
    assert_equal("finished", @blend_check_workflow.status)
    assert_equal({ "foo" => "fight" }, @blend_check_workflow.result)
    assert_equal({ "init" => 134 }, @blend_check_workflow.timing)
    assert_equal("aws_t3.micro", @blend_check_workflow.node_type)
  end

  test "blend check completion should create a settings revision" do
    assert_difference("SettingsRevision.count", 1) do
      patch api_v1_workflow_path(@blend_check_workflow), params: {
        workflow: {
          status: "finished",
          result: { "settings" => { "foo" => "bar" } },
          timing: { "init" => 134 },
          node_type: "aws_t3.micro",
        },
      }, as: :json
    end

    assert_equal("bar", @blend_check_workflow.project.settings.foo)
  end

  test "blend check completion should change the project status to checked" do
    assert @project.checking?, "status should be checking"

    patch api_v1_workflow_path(@blend_check_workflow), params: {
      workflow: {
        status: "finished",
        result: { "settings" => { "foo" => "bar" } },
        timing: { "init" => 134 },
        node_type: "aws_t3.micro",
      },
    }, as: :json

    @project.reload
    assert @project.checked?, "status should be checked"
  end
end
