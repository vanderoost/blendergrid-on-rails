class OnboardingMailer < ApplicationMailer
  default reply_to: "support@blendergrid.com"

  def signed_up_without_uploads(user)
    @user = user
    mail(
      to: user.email_address,
      subject: "uploading your first .blend file",
    )
  end

  def signed_up_without_benchmarks(user)
    @user = user
    mail(
      to: user.email_address,
      subject: "price calculations and render previews",
    )
  end

  def signed_up_without_renders(user)
    @user = user
    mail(
      to: user.email_address,
      subject: "how rendering works with Blendergrid",
    )
  end
end
