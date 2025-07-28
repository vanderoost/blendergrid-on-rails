class EmailAddressVerificationMailer < ApplicationMailer
  def verify_email_address(user)
    @user = user
    mail(subject: "Please verify your email address", to: user.email_address)
  end
end
