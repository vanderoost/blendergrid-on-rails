class InvitesController < ApplicationController
  allow_unauthenticated_access

  def show
    if user = User.find_by_token_for(:invite, params[:token])
      user.verify_email_address
      start_new_session_for(user)
      redirect_to edit_password_path(user.password_reset_token)
    else
      redirect_to new_password_path,
        alert: "This invite link is invalid or has expired."
    end
  end
end
