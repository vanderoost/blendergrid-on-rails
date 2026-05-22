class EmailAddressVerificationMailer < ApplicationMailer
  def verify_email_address(user)
    @token = user.email_address_verification_token
    mail(subject: "welcome to Blendergrid", to: user.email_address)
  end
end
