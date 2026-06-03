class UnsubscriptionsController < ApplicationController
  allow_unauthenticated_access
  # One-click unsubscribe POSTs come straight from mail providers (Gmail, Apple)
  # with no CSRF token; the signed token in the URL is what authenticates them.
  skip_forgery_protection only: :create
  before_action :set_user_by_token

  # GET /unsubscribe/:token — confirmation page. We never unsubscribe on GET so
  # that link scanners / prefetchers don't unsubscribe people by accident.
  def show
  end

  # POST /unsubscribe/:token — the actual unsubscribe (button or one-click).
  def create
    @user&.unsubscribe_from_marketing!
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for(:unsubscribe, params[:token])
    end
end
