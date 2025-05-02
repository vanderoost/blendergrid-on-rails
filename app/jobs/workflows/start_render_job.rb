class Workflows::StartRenderJob < ApplicationJob
  queue_as :default

  def perform(project)
    workflow = project.workflows.create!(
      uuid: SecureRandom.uuid,
      job_type: :render
    )

    SwarmEngine.publish_render(workflow)
  end
end
