class PaymentIntent
  include ActiveModel::Model

  attr_accessor :amount, :reason, :success_url, :cancel_url, :redirect_url

  def save
    raise "No user logged in" if Current.user.nil?

    stripe_session = Stripe::Checkout::Session.create({
      mode: "payment",
      customer_email: Current.user.email_address,
      line_items: [
        {
          price_data: {
            currency: "usd",
            unit_amount: (@amount.to_f * 100).round,
            product_data: { name: "Adding render credit" },
          },
          quantity: 1,
        },
      ],
      metadata: { reason: reason },
      success_url: success_url,
      cancel_url: cancel_url,
    })
    self.redirect_url = stripe_session.url

    true
  end
end
