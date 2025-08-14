class LandingPagesController < ApplicationController
  allow_unauthenticated_access

  def show
    landing_page = LandingPage.find_by(slug: params.fetch(:slug, "/"))
    @page_variant = landing_page.page_variants.last
  end
end
