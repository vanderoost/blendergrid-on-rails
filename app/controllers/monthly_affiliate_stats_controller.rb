class MonthlyAffiliateStatsController < ApplicationController
  before_action :set_affiliate

  def index
    @year = params[:year]&.to_i || Date.current.year
    @year = @year.clamp(2024, Date.current.year)
    @stats = @affiliate.affiliate_monthly_stats
                       .where(year: @year)
                       .order(:month)
  end

  private
    def set_affiliate
      @affiliate = Current.user.affiliate
      redirect_to account_path, alert: "You are not an affiliate" unless @affiliate
    end
end
