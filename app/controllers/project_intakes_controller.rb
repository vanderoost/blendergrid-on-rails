class ProjectIntakesController < ApplicationController
  include UploadScoped
  allow_unauthenticated_access only: %i[ create ]

  def create
    @project_intake = Project::Intake.new(project_intake_params)
    @projects = @upload.projects.order(updated_at: :desc)

    if @project_intake.save
      redirect_back fallback_location: projects_path
    else
      @quote = Quote.new
      @order = Order.new
      render "uploads/show", status: :unprocessable_content
    end
  end

  private
    def project_intake_params
      project_intake = params.fetch(:project_intake, {}).permit(blend_filepaths: [])
      { upload: @upload, blend_filepaths: project_intake[:blend_filepaths] }
    end
end
