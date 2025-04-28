class WorkflowsController < ApplicationController
  include ::ActionController::HttpAuthentication::Token::ControllerMethods

  # TOOD: Use an API namespace for "update"
  allow_unauthenticated_access # To turn off email/password login
  skip_before_action :verify_authenticity_token # To turn off CSRF protection
  before_action :authenticate, :set_workflow

  def update
    Rails.logger.info "Update Workflow - Params: #{params.inspect}"

    if params[:status] == "finished"
      @workflow.finalize(result: params[:result])
    end

    # TODO: Handle sad paths

    render json: @workflow
  end

  private
    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        Rails.logger.info "Authenticating with token: '#{token}'"
        token == Rails.application.credentials.api_token
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_workflow
      Rails.logger.info "Setting workflow #{params[:id]}"
      @workflow = Workflow.find_by(uuid: params[:id])
      Rails.logger.info "Found workflow #{@workflow.inspect}"
    end
end
