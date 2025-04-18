class WorkflowsController < ApplicationController
  include ::ActionController::HttpAuthentication::Token::ControllerMethods

  TOKEN = "secret"

  # TOOD: Figure out if this can be cleaned up for API-only routes
  allow_unauthenticated_access # To turn off email/password login
  skip_before_action :verify_authenticity_token # To turn off CSRF protection
  before_action :authenticate, :set_workflow

  def update
    if params[:status] == "finished"
      @workflow.finalize()
    end

    # TODO: Handle sad paths

    render json: @workflow
  end

  private
    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        Rails.logger.info "Authenticating with token: '#{token}'"
        token == TOKEN
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_workflow
      Rails.logger.info "Setting workflow #{params[:id]}"
      @workflow = Workflow.find_by(uuid: params[:id])
      Rails.logger.info "Found workflow #{@workflow.inspect}"
    end
end
