class Workflows::StartPriceCalculationJob < ApplicationJob
  queue_as :default

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    SwarmEngine.publish_price_calculation(workflow)
  end
end
