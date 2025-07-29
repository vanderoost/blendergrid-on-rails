class ApplicationController < ActionController::Base
  include Authentication

  def accessible_uploads
    authenticated? ? Current.user.uploads : current_guest_uploads
  end

  def current_guest_uploads
    return Upload.none unless session[:guest_email_address] # Can we skip this
    Upload.where(
      guest_email_address: session[:guest_email_address],
      guest_session_id: session.id.to_s,
      user_id: nil
    )
  end
end
