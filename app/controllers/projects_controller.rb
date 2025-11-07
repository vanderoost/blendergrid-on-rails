class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ show edit update destroy ]
  allow_unauthenticated_access only: %i[ index show edit update destroy ]

  def index
    if authenticated?
      @projects = Current.user.projects
    else
      @projects = Project.joins(:upload).where(
        upload: { id: current_guest_uploads.pluck(:id) }
      )
    end
  end

  def show
    @return_path = params.key?(:upload_id) ?
      upload_path(params[:upload_id]) : projects_path
  end

  def update
    flash[:alert] = "Error updating the scene" unless @project.update(project_params)
    redirect_back_or_to edit_project_path(@project)
  end

  def destroy
    # TODO: Check if we're allowed to delete this project in particular
    @project.cancel if @project.rendering?
    @project.update(deleted_at: Time.current)
    redirect_to projects_path
  end

  private
    def project_params
      params.expect(project: [ :current_blender_scene_id ] + Project.permitted_params)
    end

    def set_project
      @project = Project.find_by!(uuid: params[:uuid])
    end
end
