class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ show edit update ]
  allow_unauthenticated_access only: %i[ index show edit update ]

  def index
    # TODO: Only show user's or guest's projects
    # @projects = Project.joins(:upload).merge(accessible_uploads)
    @projects = Project.order(updated_at: :desc)
  end

  def show
  end

  def edit
    @return_path = params.key?(:upload_id) ?
      upload_path(params[:upload_id]) : projects_path
  end

  def update
    flash[:alert] = "Error updating the scene" unless @project.update(project_params)
    redirect_back_or_to edit_project_path(@project)
  end

  private
    def project_params
    params.expect(project: [ :current_blender_scene_id ] + Project.permitted_params)
    end

    def set_project
      @project = Project.find_by!(uuid: params[:uuid])
    end
end
