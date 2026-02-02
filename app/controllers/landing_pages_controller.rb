class LandingPagesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_landing_page, only: :show

  def show
    if @landing_page
      @top_faqs = Faq.limit(4)
    else
      render status: :not_found
    end
  end

  private
    def set_landing_page
      slug = params[:slug] || params[:path] || "/"
      @landing_page = LandingPage.find_by(slug: slug)
    end
end
