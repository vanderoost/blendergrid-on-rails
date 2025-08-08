class ProjectIntakesController < ApplicationController
  include UploadScoped
  allow_unauthenticated_access only: %i[ create ]

  def create
    @project_intake = Project::Intake.new project_intake_params

    if @project_intake.save
      redirect_to @upload, notice: "Projects created successfully!"
    else
      redirect_to @upload, status: :unprocessable_entity
    end
  end

  private
    def project_intake_params
      params.expect(project_intake: [ blend_filepaths: [] ]).merge(upload: @upload)
    end
end
