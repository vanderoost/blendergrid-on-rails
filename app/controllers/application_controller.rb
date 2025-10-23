class ApplicationController < ActionController::Base
  include Authentication
  include RequestTracking

  # TODO: Consider moving these to a concern
  def accessible_uploads
    authenticated? ? Current.user.uploads : current_guest_uploads
  end

  def current_guest_uploads
    return Upload.none unless session[:guest_email_address] # TODO: Can we skip this?
    Upload.where(
      guest_email_address: session[:guest_email_address],
      guest_session_id: session.id.to_s,
      user_id: nil
    )
  end

  private
    def redirect_to_safe_url(url)
      return redirect_to projects_path if url.blank?

      uri = URI.parse(url)
      if uri.host == "checkout.stripe.com"
        redirect_to url, allow_other_host: true
      else
        redirect_to projects_path
      end
    rescue URI::InvalidURIError
      redirect_to projects_path
    end
end
