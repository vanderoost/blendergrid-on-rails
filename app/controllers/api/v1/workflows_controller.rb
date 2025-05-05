class Api::V1::WorkflowsController < ApplicationController
  include ::ActionController::HttpAuthentication::Token::ControllerMethods

  allow_unauthenticated_access # To turn off email/password login
  skip_before_action :verify_authenticity_token # To turn off CSRF protection
  before_action :authenticate, :set_workflow

  def update
    if params[:status] == "finished"
      @workflow.finalize(result: params[:result], timing: params[:timing])
    end

    # TODO: Handle sad paths

    render json: @workflow
  end

  private
    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        token == Rails.application.credentials.api_token
      end
    end

    def set_workflow
      @workflow = Workflow.find_by(uuid: params[:id])
    end
end
