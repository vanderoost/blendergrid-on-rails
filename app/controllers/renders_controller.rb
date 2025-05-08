class RendersController < ApplicationController
  allow_unauthenticated_access

  # Deprecated (run via Stripe webhook)
  def create
    for project in Project.where(uuid: params[:project_uuids])
      # Handle Stripe

      # project.start_render
    end

    redirect_to projects_path, notice: "Render started!"
  end
end
