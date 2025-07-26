class ProjectBatchesController < ApplicationController
  include UploadScoped
  allow_unauthenticated_access only: %i[ create ]

  def create
    @project_batch = @upload.new_project_batch(project_batch_params)
    if @project_batch.save
      redirect_to @upload, notice: "Projects created successfully!"
    else
      redirect_to @upload, status: :unprocessable_entity
    end
  end

  private
    def project_batch_params
      params.expect(blend_filepaths: [])
    end
end
