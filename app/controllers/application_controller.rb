class ApplicationController < ActionController::Base
  include Authentication
  include RequestTracking

  private
    def redirect_to_safe_url(url)
      return redirect_to projects_path if url.blank?

      uri = URI.parse(url)
      if [ "checkout.stripe.com", "connect.stripe.com" ].include? uri.host
        redirect_to url, allow_other_host: true
      else
        redirect_back_or_to root_path
      end
    rescue URI::InvalidURIError
      redirect_to projects_path
    end
end
