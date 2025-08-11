class Api::BaseController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from StandardError, with: :internal_server_error

  private
    def not_found(error)
      render json: { error: "Not found", message: error.message }, status: :not_found
    end

    def internal_server_error(error)
      Rails.logger.error "#{error.class}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n") if error.backtrace

      if Rails.env.development? || Rails.env.test?
        render json: {
          error: "Internal server error",
          message: error.message,
          backtrace: error.backtrace&.first(10),
        }, status: :internal_server_error
      else
        render json: { error: "Internal server error" }, status: :internal_server_error
      end
    end
end
