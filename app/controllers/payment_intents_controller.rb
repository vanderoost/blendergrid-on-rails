class PaymentIntentsController < ApplicationController
  def create
    @payment_intent = PaymentIntent.new(payment_intent_params)

    if @payment_intent.save
      redirect_to_safe_url @payment_intent.redirect_url
    else
      redirect_back fallback_location: account_path, status: :unprocessable_content
    end
  end

  private
    def payment_intent_params
      params.expect(payment_intent: [ :amount, :reason ]).merge(
        success_url: account_url, cancel_url: account_url
      )
    end
end
