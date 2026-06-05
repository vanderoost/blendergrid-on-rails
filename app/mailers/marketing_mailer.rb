class MarketingMailer < ApplicationMailer
  # Marketing mail sends from the dedicated mail.blendergrid.com subdomain so its
  # sending reputation stays isolated from transactional mail on blendergrid.com.
  # The SES configuration set routes these through the "marketing" suppression
  # list (bounces/complaints are auto-suppressed).
  default from:      "Richard from Blendergrid <richard@mail.blendergrid.com>",
          reply_to:  "richard@blendergrid.com",
          "X-SES-CONFIGURATION-SET" => "marketing"

  # Marketing emails share a wider, branded HTML shell (see the layout); the
  # plain "mailer" layout stays on transactional mail.
  layout "marketing_mailer"

  # The drip campaign: each entry is one email and how long after a user verifies
  # their email address it should send. SendDripEmailsJob reads this hourly. To
  # add or retime a drip email, edit this list, add the matching method below, and
  # add its two view templates (.html.erb + .text.erb). Steps are independent —
  # each is sent at most once per user, deduped on its own action. The `after:`
  # values set the order, so names carry no number: a new email can slot in
  # anywhere without renaming (and the action is a permanent dedup key — never
  # rename one once it has shipped).
  DRIP_SEQUENCE = [
    { action: :drip_adaptive_sampling,  after: 3.days },
    { action: :drip_realistic_lighting, after: 7.days },
    { action: :drip_path_guiding,       after: 14.days },
  ].freeze

  def announcement(subscriber)
    marketing_mail(subscriber, subject: "What's new at Blendergrid")
  end

  def drip_adaptive_sampling(subscriber)
    marketing_mail(subscriber, subject: "smarter rendering (adaptive sampling)")
  end

  def drip_realistic_lighting(subscriber)
    marketing_mail(subscriber, subject: "more realistic lighting in Blender")
  end

  def drip_path_guiding(subscriber)
    marketing_mail(subscriber, subject: "less render time with path guiding")
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
