class Api::V1::WorkflowsController < Api::BaseController
  before_action :set_workflow

  def update
    if @workflow.update(workflow_params)
      render json: @workflow
    else
      render json: @workflow.errors, status: :unprocessable_entity
    end
  end

  private
    def set_workflow
      @workflow = Workflow.find_by!(uuid: params[:uuid])
    end

    def workflow_params
      params.require(:workflow).permit(
        :status,
        :node_provider_id,
        :node_type_name,
        result: {},
        timing: {}
      )
    end
end
