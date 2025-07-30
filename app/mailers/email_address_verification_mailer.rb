class EmailAddressVerificationMailer < ApplicationMailer
  def verify_email_address(user)
    @token = user.email_address_verification_token
    mail(subject: "please verify your email address", to: user.email_address)
  end
end
