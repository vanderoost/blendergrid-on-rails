class Workflows::StartIntegrityCheckJob < ApplicationJob
  queue_as :default

  def perform(project)
    workflow = project.workflows.create!(
      uuid: SecureRandom.uuid,
      job_type: :integrity_check
    )

    SwarmEngine.publish_integrity_check(workflow)
  end
end
