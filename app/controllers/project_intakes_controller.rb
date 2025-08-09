class ProjectIntakesController < ApplicationController
  include UploadScoped
  allow_unauthenticated_access only: %i[ create ]

  def create
    @project_intake = Project::Intake.new(project_intake_params)

    if @project_intake.save
      redirect_back fallback_location: projects_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def project_intake_params
      project_intake = params.fetch(:project_intake, {}).permit(blend_files: [])
      { upload: @upload, blend_files: project_intake[:blend_files] }
    end
end
