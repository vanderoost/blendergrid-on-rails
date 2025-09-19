class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ show edit ]
  allow_unauthenticated_access only: %i[ index show edit ]

  def index
    # @projects = Project.joins(:upload).merge(accessible_uploads)
    @projects = Project.all
  end

  def show
  end

  def edit
  end

  def update
    @project.update(project_params)
    redirect_to @project
  end

  private
    def project_params
      params.require(:project).permit(:name, :description, :uuid)
    end

    def set_project
      @project = Project.find_by!(uuid: params[:uuid])
    end
end
