class RendersController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[create destroy]

  def create
    @render = @project.renders.new(render_params)
    if @render.save
      redirect_back fallback_location: @project
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @render = @project.renders.find(params[:id])
    @render.destroy

    redirect_to @project
  end

  private
    def render_params
      params.expect(render: [ :cycles_samples ])
    end
end
