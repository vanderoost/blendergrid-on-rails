class LandingPagesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_landing_page, only: :show

  def show
    render status: :not_found unless @landing_page
  end

  private
    def set_landing_page
      slug = params[:slug] || params[:path] || "/"
      @landing_page = LandingPage.find_by(slug: slug)
    end
end
