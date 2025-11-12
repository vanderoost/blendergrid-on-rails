class ReverseCashRefundsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "REVERSING DELAYED CASH REFUNDS"
    CreditEntry
      .where(created_at: 32.hours.ago..24.hours.ago)
      .where(reason: "delayed_cash_refund")
      .each do |entry|
        next if entry.refund.stripe_refund_id.present?
        next if entry.user.render_credit_cents < entry.amount_cents

        puts "REVERSING DELAYED CASH REFUND FOR: #{entry.user.email_address}"
        entry.user.credit_entries.create!(
          amount_cents: -entry.amount_cents,
          refund: entry.refund,
          reason: "reversed_cash_refund",
        )
        entry.refund.refund_stripe
    end
  end
end
