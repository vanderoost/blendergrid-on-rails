class Api::V1::WorkflowsController < Api::BaseController
  before_action :set_workflow

  def update
    if params[:status] == "finished"
      @workflow.handle_result params[:result]
      @workflow.finish
    elsif params[:status] == "failed"
      @workflow.fail
    end

    render json: @workflow
  end

  private
    def set_workflow
      @workflow = Workflow.find_by!(uuid: params[:uuid])
    end
end
