class ProjectIntakesController < ApplicationController
  include UploadScoped
  allow_unauthenticated_access only: %i[ create ]

  def create
    @project_intake = Project::Intake.new project_intake_params

    if @project_intake.save
      redirect_back fallback_location: projects_path, notice: "Projects created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def project_intake_params
      # params.expect(project_intake: [ blend_filepaths: [] ]).merge(upload: @upload)
      params.fetch(:project_intake, {})
        .permit(blend_filepaths: [])
        .merge(upload: @upload)
    end
end
