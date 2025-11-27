class EmailSubscriptionsController < ApplicationController
  allow_unauthenticated_access

  def new
    @email_subscription = EmailSubscription.new
  end

  def create
    @email_subscription = EmailSubscription.new email_subscription_params
    if @email_subscription.save
      render @email_subscription
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def email_subscription_params
    params.expect(email_subscription: [ :email_address ])
  end
end
