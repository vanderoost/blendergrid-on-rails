class UnsubscribesController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection only: :create
  before_action :set_user_by_token

  def show
  end

  def create
    @user&.unsubscribe_from_marketing!
  end

  def destroy
    @user&.subscribe_to_marketing!
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for(:unsubscribe, params[:token])
    end
end
