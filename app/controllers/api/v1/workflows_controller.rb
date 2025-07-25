class Api::V1::WorkflowsController < Api::BaseController
  before_action :set_workflow

  def update
    if params[:status] == "finished"
      @workflow.handle_result workflow_params
    elsif params[:status] == "failed"
      @workflow.fail
    end

    render json: @workflow
  end

  private
    def set_workflow
      @workflow = Workflow.find_by!(uuid: params[:uuid])
    end

    # TODO: So ugly - Update the Swarm Engine to send us better data
    def workflow_params
      workflow_params = params[:result].merge({
        timing: params.dig(:timing)
      })

      if params.dig(:node_type).present?
        node_provider_id, node_type_name = params[:node_type].split(":")
        workflow_params = workflow_params.merge({
          node_provider_id: node_provider_id,
          node_type_name: node_type_name
        })
      end

      workflow_params
    end
end
