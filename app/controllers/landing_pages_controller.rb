class LandingPagesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_landing_page, only: :show

  def show
    if @landing_page
      @referral_code = valid_referral_code(params[:ref])
      @top_faqs = Faq.limit(4)
    else
      render status: :not_found
    end
  end

  private
    def valid_referral_code(code)
      return nil if code.blank?
      code if Affiliate.exists?(referral_code: code)
    end

    def set_landing_page
      slug = params[:slug] || params[:path] || "/"
      @landing_page = LandingPage.find_by(slug: slug)
    end
end
