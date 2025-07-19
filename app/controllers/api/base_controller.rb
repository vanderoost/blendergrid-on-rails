class Api::BaseController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private
    def not_found(error)
      render json: { error: error.message }, status: :not_found
    end
end
