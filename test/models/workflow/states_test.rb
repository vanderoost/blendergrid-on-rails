require "test_helper"

class Workflow::StatesTest < ActiveSupport::TestCase
  test "a created workflow can start" do
    workflow = workflows(:created_workflow)
    assert workflow.created?, "Workflow should be created"
    workflow.start
    assert workflow.started?, "Workflow should be started"
  end

  test "a workflow can not start if its state is not created" do
    Workflow.statuses.except(:created).keys.each do |status|
      workflow = Workflow.new(status: status)

      assert_raises(Error::ForbiddenTransition) do
        workflow.start
      end

      assert workflow.status == status, "Workflow status is not #{status}"
    end
  end

  test "a started workflow can finish" do
    workflow = workflows(:started_workflow)
    assert workflow.started?, "Workflow should be started"
    workflow.finish
    assert workflow.finished?, "Workflow should be finished"
  end

  test "a started workflow can be stopped" do
    workflow = workflows(:started_workflow)
    assert workflow.started?, "Workflow should be started"
    workflow.stop
    assert workflow.stopped?, "Workflow should be stopped"
  end

  test "a started workflow can fail" do
    workflow = workflows(:started_workflow)
    assert workflow.started?, "Workflow should be started"
    workflow.fail
    assert workflow.failed?, "Workflow should be failed"
  end
end
