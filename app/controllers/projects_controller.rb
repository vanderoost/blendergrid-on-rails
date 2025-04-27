class ProjectsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    projects = []
    Array(session[:project_source_uuids]).each do |project_source_uuid|
      project_source = ProjectSource.find_by(uuid: project_source_uuid)
      if not project_source or project_source.projects.empty?
        session[:project_source_uuids].delete(project_source_uuid)
        next
      end
      projects += project_source.projects
    end

    @projects = projects.sort_by(&:created_at).reverse
  end

  def show
    @project = Project.find(params[:id])
  end
end
