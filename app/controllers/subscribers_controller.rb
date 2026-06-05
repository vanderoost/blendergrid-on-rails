class SubscribersController < ApplicationController
  allow_unauthenticated_access

  def new
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.for_subscription(
      email:  subscriber_params[:guest_email_address],
      name:   subscriber_params[:name],
      source: "newsletter",
    )

    if @subscriber.save
      render @subscriber
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def subscriber_params
      params.expect(subscriber: [ :name, :guest_email_address ])
    end
end
