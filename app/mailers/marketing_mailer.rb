class MarketingMailer < ApplicationMailer
  # Marketing mail sends from the dedicated mail.blendergrid.com subdomain so its
  # sending reputation stays isolated from transactional mail on blendergrid.com.
  # The SES configuration set routes these through the "marketing" suppression
  # list (bounces/complaints are auto-suppressed).
  default from:      "Richard from Blendergrid <richard@mail.blendergrid.com>",
          reply_to:  "richard@blendergrid.com",
          "X-SES-CONFIGURATION-SET" => "marketing"

  def announcement(user)
    @user = user
    @session_token = user.generate_token_for(:session)
    mail(
      to: user.email_address,
      subject: "What's new at Blendergrid",
    )
  end
end
