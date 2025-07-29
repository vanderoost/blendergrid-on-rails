module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
    helper_method :has_session?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :resume_session
    end
  end

  private
    def require_authentication
      authenticated? || request_authentication
    end

    def authenticated?
      has_session? && Current.user.registered?
    end

    def has_session?
      resume_session
    end

    def resume_session
      Current.session ||= find_session_by_cookie
      return Current.session unless params.key?(:session_token)

      token_user = User.find_by_token_for(:session, params[:session_token])
      if token_user.nil?
        flash[:alert] = "Invalid session token"
        return Current.session
      end

      logger.info "Token user: #{token_user.inspect}"
      start_new_session_for token_user
      flash[:notice] = "Valid session token"
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      email_address = user.email_address || user.guest_email_address

      if Current.user&.unidentified? ||
      Current.user&.guest_email_address == email_address
        Current.user.uploads.update_all(user_id: user.id)
      end

      user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      ).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = {
          value: session.id,
          httponly: true,
          same_site: :lax
        }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
