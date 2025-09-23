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
  end

  def update
    # TODO
    redirect_back fallback_location: @project
  end

  private
    def project_params
      params.require(:project).permit(draft_settings: {})
    end

    def set_project
      @project = Project.find_by!(uuid: params[:uuid])
    end
end
