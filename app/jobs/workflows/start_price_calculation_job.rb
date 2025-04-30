class Workflows::StartPriceCalculationJob < ApplicationJob
  queue_as :default

  def perform(project)
    workflow = project.workflows.create!(
      uuid: SecureRandom.uuid,
      job_type: :price_calculation
    )

    SwarmEngine.publish_price_calculation(workflow)
  end
end
