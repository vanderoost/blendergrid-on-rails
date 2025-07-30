class EmailAddressVerification
  def initialize(user) = @user = user

  def save
    # TODO: Check when the last verification email was sent, only send one every x hours
    EmailAddressVerificationMailer.verify_email_address(@user).deliver_later
  end
end
