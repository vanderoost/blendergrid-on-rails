class RendersController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    @render = @project.renders.new(render_params)
    if @render.save
      redirect_back fallback_location: @project
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def render_params
      params.expect(render: [ :cycles_samples ])
    end
end
