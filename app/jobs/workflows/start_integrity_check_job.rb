class Workflows::StartIntegrityCheckJob < ApplicationJob
  queue_as :default

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    SwarmEngine.publish_integrity_check(workflow)
  end
end
