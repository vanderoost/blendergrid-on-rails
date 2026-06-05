# Preview all emails at http://localhost:3000/rails/mailers/marketing_mailer
class MarketingMailerPreview < ActionMailer::Preview
  def announcement
    MarketingMailer.announcement(subscriber)
  end

  def drip_adaptive_sampling
    MarketingMailer.drip_adaptive_sampling(subscriber)
  end

  def drip_realistic_lighting
    MarketingMailer.drip_realistic_lighting(subscriber)
  end

  def drip_path_guiding
    MarketingMailer.drip_path_guiding(subscriber)
  end

  private
    # A real (persisted) subscriber so generate_token_for(:unsubscribe) and the
    # user's :session magic-login link resolve. Falls back to a built guest one
    # if the dev db has no subscribers yet.
    def subscriber
      Subscriber.subscribed.first ||
        Subscriber.new(name: "Alex", guest_email_address: "alex@example.com")
    end
end
