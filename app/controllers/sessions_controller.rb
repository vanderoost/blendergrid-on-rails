class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Slow down, turbo racer!" }

  def new
  end

  def create
    permitted = params.permit(:email, :password, :remember_me)

    if (user = User.authenticate_by(permitted.slice(:email, :password)))
      start_new_session_for user, remember: params[:remember_me] == "1"

      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
