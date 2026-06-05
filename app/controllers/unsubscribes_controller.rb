class UnsubscribesController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection only: :create
  before_action :set_subscriber_by_token

  def show
  end

  def create
    @subscriber&.unsubscribe!
  end

  def destroy
    @subscriber&.subscribe!
  end

  private
    def set_subscriber_by_token
      @subscriber = Subscriber.find_by_token_for(:unsubscribe, params[:token])
    end
end
