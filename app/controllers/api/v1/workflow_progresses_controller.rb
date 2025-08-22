class Api::V1::WorkflowProgressesController < Api::BaseController
  before_action :set_workflow_progress, only: [ :update ]

  def update
    if @workflow_progress.update workflow_progress_params
      render json: @workflow_progress
    else
      render json: @workflow_progress.errors, status: :unprocessable_entity
    end
  end

  private
    def set_workflow_progress
      @workflow_progress = WorkflowProgress.new
    end

    def workflow_progress_params
      params.expect(workflow_progress: {
        workflows: [ [ :uuid, :progress_permil, :eta ] ],
      })
    end
end
