class ProjectsController < ApplicationController
  before_action :set_project, only: :show
  allow_unauthenticated_access only: %i[ index show ]

  def index
    @projects = Current.user&.projects || []
  end

  def show
  end

  private
    def set_project
      @project = Project.find_by!(uuid: params[:uuid])
    end
end
