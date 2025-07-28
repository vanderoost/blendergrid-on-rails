class EmailAddressVerificationsController < ApplicationController
  allow_unauthenticated_access only: %i[ show new create ]

  def show
    @user = User.find_by_email_address_verification_token(params[:token])

    if @user.present?
      @user.verify_email_address
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to Blendergrid!"
    else
      redirect_to root_path, alert: "Invalid token"
    end
  end

  def new
  end

  def create
    UserMailer.verify_email_address(Current.user).deliver_later
    # Handle response: render a JSON payload or redirect to another page
  end
end
