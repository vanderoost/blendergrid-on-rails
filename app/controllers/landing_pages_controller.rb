class LandingPagesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_landing_page, only: :show

  def show
  end

  private
    def set_landing_page
      @landing_page = LandingPage.find_by(slug: params.fetch(:slug, "/"))
    end
end
