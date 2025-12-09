# Run this daily

class FundGlobalPayoutBalanceJob < ApplicationJob
  queue_as :default

  def perform
    puts "Total rewards: #{total_rewards_cents}"
    puts "Current balance: #{storage_balance_cents}"

    missing_amount_cents = [ total_rewards_cents - storage_balance_cents, 0 ].max
    puts "Missing amount: #{missing_amount_cents}"

    if missing_amount_cents.zero?
      puts "No need to fund the Global Payouts Storage balance this time"
      return
    end

    puts "Payments balance: #{payments_balance_cents}"

    to_transfer = [ missing_amount_cents, payments_balance_cents ].min
    transfer_payments_to_storage(to_transfer)
  end

  private
    def total_rewards_cents
      @total_rewards_cents ||= AffiliateMonthlyStat
        # TODO: Set this up later to prevent too many entries
        # .where(
        #   year: Date.yesterday.year,
        #   month: Date.yesterday.month,
        # )
        .where(rewards_cents: 1..)
        .where(paid_out_at: nil)
        .sum(:rewards_cents)
    end

    def storage_balance_cents
      @storage_balance_cents ||= fetch_storage_balance_cents
    end

    def fetch_storage_balance_cents
      available_cents = financial_account.balance.available.usd.value
      pending_cents = financial_account.balance.inbound_pending.usd.value
      available_cents + pending_cents
    end

    def payments_balance_cents
      @payments_balance_cents ||= fetch_payments_balance_cents
    end

    def fetch_payments_balance_cents
      payments_balance = Stripe::Balance.retrieve()
      payments_balance.available.first.amount
    end

    def transfer_payments_to_storage(amount_cents)
      puts "Transferring: #{amount_cents}"

      payout = Stripe::Payout.create({
        payout_method: financial_account.id,
        amount: amount_cents,
        currency: "usd",
      })

      puts "Payout created: #{payout.inspect}"
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
