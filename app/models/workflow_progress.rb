class WorkflowProgress
  def update(params)
    params["workflows"].each do |workflow_data|
      workflow = Workflow.find_by(uuid: workflow_data["uuid"])
      next unless workflow.present?

      workflow.update(
        progress_permil: workflow_data["progress_permil"],
        eta: Time.at(workflow_data["eta"].to_i)
      )
    end

    true
  end
end
