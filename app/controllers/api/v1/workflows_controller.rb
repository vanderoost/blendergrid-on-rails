class Api::V1::WorkflowsController < ApplicationController
  before_action :set_workflow
  skip_before_action :verify_authenticity_token # Turn off CSRF protection

  def update
    if @workflow.nil?
      render json: { error: "Workflow not found" }, status: :not_found
    elsif params[:status] == "finished"
      @workflow.finish
      render json: @workflow
    elsif params[:status] == "failed"
      @workflow.fail
      render json: @workflow
    end
  end

  private
    def set_workflow
      @workflow = Workflow.find_by(uuid: params[:id])
    end
end
