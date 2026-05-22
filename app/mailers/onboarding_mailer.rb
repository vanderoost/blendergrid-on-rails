class OnboardingMailer < ApplicationMailer
  default reply_to: "support@blendergrid.com"

  def signed_up_without_uploads(user)
    @user = user
    @session_token = user.generate_token_for(:session)
    mail(
      to: user.email_address,
      subject: "uploading your first .blend file",
    )
  end

  def signed_up_without_benchmarks(user)
    @user = user
    @session_token = user.generate_token_for(:session)
    mail(
      to: user.email_address,
      subject: "price calculations and render previews",
    )
  end

  def signed_up_without_renders(user)
    @user = user
    @session_token = user.generate_token_for(:session)
    mail(
      to: user.email_address,
      subject: "what your render costs (and how to lower it)",
    )
  end
end
