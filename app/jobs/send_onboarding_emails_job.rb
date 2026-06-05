class SendOnboardingEmailsJob < ApplicationJob
  VERIFIED_MIN_AGE = 1.hour    # wait at least this long after verifying
  VERIFIED_MAX_AGE = 3.days    # don't onboard accounts older than this

  queue_as :default

  def perform
    recently_verified_users.find_each do |user|
      next if onboarding_email_sent?(user.email_address)

      action = onboarding_action_for(user)
      next if action.nil? # already activated

      OnboardingMailer.public_send(action, user).deliver_later
    end
  end

  private
    # Only nudge users with a live marketing subscription (new signups always have
    # one via User#create_or_promote_subscriber).
    def recently_verified_users
      User
        .where(email_address_verified_at: VERIFIED_MAX_AGE.ago..VERIFIED_MIN_AGE.ago)
        .joins(:subscriber).merge(Subscriber.subscribed)
    end

    # Pick the email for the earliest funnel step the user is stuck on, or nil
    # if they've already rendered (activated — no nudge needed).
    def onboarding_action_for(user)
      if !user.uploads.exists?
        :signed_up_without_uploads
      elsif !user.projects.joins(:benchmarks).exists?
        :signed_up_without_benchmarks
      elsif !user.projects.joins(:renders).exists?
        :signed_up_without_renders
      end
    end

    # Matches on mailer_class only, so any one of the three variants counts —
    # a user gets exactly one onboarding email, ever.
    def onboarding_email_sent?(email_address)
      Email
        .where(email_address: email_address, mailer_class: "OnboardingMailer")
        .exists?
    end
end
