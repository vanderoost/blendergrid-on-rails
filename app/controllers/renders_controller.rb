class RendersController < ApplicationController
  allow_unauthenticated_access

  def create
    for project in Project.where(uuid: params[:project_uuids])
      project.start_render
    end

    redirect_to projects_path, notice: "Render started!"
  end
end
