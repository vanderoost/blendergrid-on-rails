class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ show edit update ]
  allow_unauthenticated_access only: %i[ index show edit update ]

  def index
    # @projects = Project.joins(:upload).merge(accessible_uploads)
    @projects = Project.all
  end

  def show
  end

  def edit
    @return_path = params[:return_path] || projects_path
  end

  def update
    flash[:alert] = "Error updating the scene" unless @project.update(project_params)
    redirect_to edit_project_path(@project)
  end

  private
    def project_params
      params.expect(project: [ :current_blender_scene_id ])
    end

    def set_project
      @project = Project.find_by!(uuid: params[:uuid])
    end
end
