class EmailAddressVerificationsController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by_email_address_verification_token(params[:token])
    if @user.present?
      @user.verify_email_address
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome to Blendergrid!"
    else
      redirect_to new_session, alert: "Invalid verification link. (Probably expired)"
    end
  end
end
