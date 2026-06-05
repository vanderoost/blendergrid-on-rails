class MarketingMailer < ApplicationMailer
  # Marketing mail sends from the dedicated mail.blendergrid.com subdomain so its
  # sending reputation stays isolated from transactional mail on blendergrid.com.
  # The SES configuration set routes these through the "marketing" suppression
  # list (bounces/complaints are auto-suppressed).
  default from:      "Richard from Blendergrid <richard@mail.blendergrid.com>",
          reply_to:  "richard@blendergrid.com",
          "X-SES-CONFIGURATION-SET" => "marketing"

  def announcement(subscriber)
    marketing_mail(subscriber, subject: "What's new at Blendergrid")
  end

  private
    # Wraps `mail` for every marketing send: skips unsubscribed recipients and
    # adds the RFC 8058 one-click unsubscribe headers plus an @unsubscribe_url for
    # the visible footer link. @session_token is only set for subscribers that are
    # registered users (guests get no magic-login link).
    def marketing_mail(subscriber, **options)
      return if subscriber.unsubscribed?

      @subscriber = subscriber
      @session_token = subscriber.user&.generate_token_for(:session)
      @unsubscribe_url = unsubscribe_url(subscriber.generate_token_for(:unsubscribe))

      mail(
        to: subscriber.email_address,
        "List-Unsubscribe" => "<#{@unsubscribe_url}>",
        "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click",
        **options,
      )
    end
end
