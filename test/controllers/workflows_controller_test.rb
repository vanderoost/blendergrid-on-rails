require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  test "should set status, result, timing, and node type" do
    workflow = workflows(:started_workflow)
    patch api_v1_workflow_path(workflow), params: {
      workflow: {
        status: "finished",
        result: { "foo" => "fight" },
        timing: { "init" => 134 },
        node_type: "aws_t3.micro",
      },
    }, as: :json

    workflow.reload
    assert_equal("finished", workflow.status)
    assert_equal({ "foo" => "fight" }, workflow.result)
    assert_equal({ "init" => 134 }, workflow.timing)
    assert_equal("aws_t3.micro", workflow.node_type)
  end

  test "blend check completion should create a settings revision" do
    workflow = workflows(:started_workflow)

    assert_difference("SettingsRevision.count", 1) do
      patch api_v1_workflow_path(workflow), params: {
        workflow: {
          status: "finished",
          result: { "settings" => { "foo" => "bar" } },
          timing: { "init" => 134 },
          node_type: "aws_t3.micro",
        },
      }, as: :json
    end

    assert_equal("bar", workflow.project.settings.foo)
  end

  test "blend check completion should change the project status to checked" do
    workflow = workflows(:started_workflow)
    assert workflow.project.checking?, "status should be checking"

    assert_difference("SettingsRevision.count", 1) do
      patch api_v1_workflow_path(workflow), params: {
        workflow: {
          status: "finished",
          result: { "settings" => { "foo" => "bar" } },
          timing: { "init" => 134 },
          node_type: "aws_t3.micro",
        },
      }, as: :json
    end

    workflow.project.reload
    assert workflow.project.checked?, "status should be checked"
  end
end
