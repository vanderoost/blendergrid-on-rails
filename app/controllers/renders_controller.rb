class RendersController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    @render = @project.build_render
    if @render.save
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end
end
