class ProjectsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    Rails.logger.info "Project Source UUIDs: #{session[:project_source_uuids]}"
    projects = []

    Array(session[:project_source_uuids]).each do |project_source_uuid|
      project_source = ProjectSource.find_by(uuid: project_source_uuid)
      next if not project_source
      projects += project_source.projects
    end

    @projects = projects.sort_by(&:name)
  end

  def show
    @project = Project.find(params[:id])
  end
end
