class SessionsController < ApplicationController
  include UploadStashable

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      if user.email_address_verified?
        logger.info "AUTHENTICATED & VERIFIED #{user.email_address}"
        start_new_session_for user
        claim_stashed_uploads user
        redirect_to after_authentication_url
      else
        logger.info "AUTHENTICATED BUT NOT VERIFIED #{user.email_address}"
        redirect_to new_email_address_verification_path
      end
    else
      logger.info "AUTHENTICATION FAILED #{params[:email_address]}"
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
