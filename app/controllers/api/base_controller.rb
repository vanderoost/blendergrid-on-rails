class Api::BaseController < ActionController::API
  include ApiAuthentication

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing,
    with: :handle_bad_request
  rescue_from StandardError, with: :handle_internal_server_error

  private
    def handle_not_found(exception)
      Rails.logger.info(
        "Record not found: #{exception.class} - #{exception.message}"
      )
      render(
        json: {
          error: "Not found",
          message: exception.message || "Resource not found",
        },
        status: 404
      )
    end

    def handle_bad_request(exception)
      Rails.logger.info(
        "Bad request: #{exception.class} - #{exception.message}"
      )
      render(
        json: {
          error: "Bad request",
          message: exception.message || "Invalid parameters",
        },
        status: 400
      )
    end

    def handle_internal_server_error(exception)
      Rails.logger.error(
        "Internal server error: #{exception.class} - #{exception.message}"
      )
      Rails.logger.error(
        exception.backtrace.join("\n")
      ) if exception.backtrace

      if Rails.env.development? || Rails.env.test?
        render(
          json: {
            error: "Internal server error",
            message: exception.message || "An unexpected error occurred",
            backtrace: exception.backtrace&.first(10),
          },
          status: 500
        )
      else
        render(
          json: {
            error: "Internal server error",
            message: "An unexpected error occurred",
          },
          status: 500
        )
      end
    end
end
