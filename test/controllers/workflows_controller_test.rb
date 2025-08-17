require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  test "should set result, timing and node type" do
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

  # test "should handle finished blend check workflow" do
  #   # Test that when a started BlendCheck Workflow is updated to finished, the
  #   Workflow # state is updated to finished, a SettingsRevision is created, and the
  #   Project state # becomes checked.
  #
  #   workflow = workflows(:started_workflow)
  #   patch api_v1_workflow_path(workflow), params: {
  #     workflow: {
  #       result: { "foo" => "fight" },
  #       timing: { "init" => 134 },
  #       node_type: "aws_t3.micro",
  #     },
  #   }, as: :json
  # end
end
