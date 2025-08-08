class Order::Checkout
  def initialize(order)
    @order = order
  end

  def handle
    start_stripe_session
  end

  private
    def start_stripe_session
      stripe_session = Stripe::Checkout::Session.create(
        mode: "payment",
        customer_email: "suzanne@blender.org", # So it's prefilled (use nil if unknown)
        line_items: create_line_items,
        metadata: { order_id: @order.id.to_s },
        success_url: @order.success_url,
        cancel_url: @order.cancel_url
      )
      @order.stripe_session_id = stripe_session.id
      @order.redirect_url = stripe_session.url
      @order.save
    end

    def create_line_items
      @order.items.map do |item|
        {
          price_data: {
            currency: "usd",
            unit_amount: item.project.price_cents,
            product_data: { name: item.project.blend_filepath }
          },
          quantity: 1
        }
      end
    end
end
