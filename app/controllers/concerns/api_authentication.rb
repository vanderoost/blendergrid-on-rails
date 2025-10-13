module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_api_token
  end

  private
    def authenticate_with_api_token
      token = extract_token_from_header

      if token.blank?
        render json: { error: "API token required" }, status: :unauthorized
        return
      end

      @current_api_token = ApiToken.authenticate(token)
      unless @current_api_token
        render json: { error: "Invalid API token" }, status: :unauthorized
      end
    end

    def extract_token_from_header
      auth_header = request.headers["Authorization"]
      return nil if auth_header.blank?

      auth_header.sub(/^Bearer /, "")
    end

    def current_api_token
      @current_api_token
    end
end
