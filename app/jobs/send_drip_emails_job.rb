class SendDripEmailsJob < ApplicationJob
  # Drip only targets accounts verified at/after launch, so the existing
  # back-catalog of verified users is never enrolled. Set to the deploy date.
  LAUNCH_CUTOFF = Time.utc(2026, 6, 3)

  queue_as :default

  def perform
    MarketingMailer::DRIP_SEQUENCE.each do |step|
      due_users(step[:after]).find_each do |user|
        next if drip_email_sent?(user.email_address, step[:action])

        MarketingMailer.public_send(step[:action], user.subscriber).deliver_later
      end
    end
  end

  private
    # Delay elapsed (verified_at <= after.ago) and verified after launch, still
    # holding a live marketing subscription.
    def due_users(after)
      User
        .where(email_address_verified_at: LAUNCH_CUTOFF..after.ago)
        .joins(:subscriber).merge(Subscriber.subscribed)
    end

    # Dedup on the exact action, so each drip email is sent at most once per user
    # and never collides with `announcement` (also a MarketingMailer send).
    def drip_email_sent?(email_address, action)
      Email.where(
        email_address: email_address,
        mailer_class: "MarketingMailer",
        action: action,
      ).exists?
    end
end
