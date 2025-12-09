class ApplicationController < ActionController::Base
  include Authentication
  include RequestTracking

  private
    def redirect_to_safe_url(url)
      return redirect_back_or_to root_path if url.blank?

      uri = URI.parse(url)
      if [ "checkout.stripe.com", "accounts.stripe.com" ].include? uri.host
        redirect_to url, allow_other_host: true
      else
        redirect_back_or_to root_path
      end
    rescue URI::InvalidURIError
      redirect_back_or_to root_path
    end
end
