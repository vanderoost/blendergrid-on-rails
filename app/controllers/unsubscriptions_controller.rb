class UnsubscriptionsController < ApplicationController
  allow_unauthenticated_access
  # Every action is authenticated solely by the unguessable signed token in the
  # URL (no session/cookie), so CSRF protection adds nothing here — and the RFC
  # 8058 one-click POST from mail providers carries no token.
  skip_forgery_protection
  before_action :set_user_by_token

  # GET — landing page. The view auto-submits the unsubscribe POST when the user
  # is still subscribed; otherwise it shows the unsubscribed/invalid state.
  def show
  end

  # POST — unsubscribe. Serves both the in-email link's JS auto-submit and the
  # native one-click button in Gmail/Apple (List-Unsubscribe-Post, RFC 8058).
  def create
    @user&.unsubscribe_from_marketing!
  end

  # DELETE — re-subscribe (undo).
  def destroy
    @user&.resubscribe_to_marketing!
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for(:unsubscribe, params[:token])
    end
end
