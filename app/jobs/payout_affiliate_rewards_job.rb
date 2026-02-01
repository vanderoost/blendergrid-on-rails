# Run this at the first day of each month

class PayoutAffiliateRewardsJob < ApplicationJob
  MIN_AGE_DAYS = 35
  queue_as :default

  def perform
    affiliates.each do |affiliate|
      payout_affiliate affiliate
    end
  end

  private
    def affiliates
      @affiliates ||= Affiliate
      .includes(:user, :affiliate_monthly_stats)
      .joins(:affiliate_monthly_stats)
      .where(affiliate_monthly_stats: {
        created_at: ..MIN_AGE_DAYS.days.ago,
        rewards_cents: 1..,
        paid_out_at: nil,
      })
    end

    def payout_affiliate(affiliate)
      puts "Affiliate User: #{affiliate.user.email_address}"
      puts "Total rewards: #{affiliate.affiliate_monthly_stats.sum(:rewards_cents)}"
      affiliate.affiliate_monthly_stats.each do |monthly_stat|
        payout_monthly_rewards monthly_stat
      end
    end

    def payout_monthly_rewards(monthly_stat)
      puts "Rewards #{monthly_stat.year}-#{monthly_stat.month}:"\
        " #{monthly_stat.rewards_cents}"
      return unless monthly_stat.rewards_cents.positive?

      puts "Create Payout for Stripe account:"\
        " #{monthly_stat.affiliate.stripe_account_id}"
      outbound_payment = stripe_client.v2.money_management.outbound_payments.create({
        from: {
          financial_account: financial_account.id,
          currency: "usd",
        },
        to: { recipient: monthly_stat.affiliate.stripe_account_id },
        amount: {
          value: monthly_stat.rewards_cents,
          currency: "usd",
        },
        description: "Blendergrid Affiliate Rewards"\
          " #{monthly_stat.year}-#{monthly_stat.month}",
      })
      puts "Outbound payment created: #{outbound_payment.inspect}"

      monthly_stat.update(paid_out_at: Time.current)
    end

    def financial_account
      @financial_account ||= fetch_financial_account
    end

    def fetch_financial_account
      financial_accounts = stripe_client.v2.money_management.financial_accounts.list()
      financial_accounts.data.first
    end

    def stripe_client
      @client ||= Stripe::StripeClient.new(Stripe.api_key)
    end
end
