class Order::Checkout
  def initialize(order)
    @order = order
    @applied_credit_cents = 0
  end

  def start_checkout_session
    apply_render_credit

    # TODO: See if this can be cleaner, this is kind of the second time we calculate
    # this
    net_amount_cents = @order.price_cents - @applied_credit_cents
    if net_amount_cents.zero?
      @order.redirect_url = @order.success_url
      @order.fulfill

    else
      # If there's any amount left, create a Stripe session
      stripe_session = Stripe::Checkout::Session.create(stripe_session_params)
      @order.stripe_session_id = stripe_session.id
      @order.redirect_url = stripe_session.url
    end

    @order.save
  end

  private
    def apply_render_credit
      return unless @order.user
      return if @order.user.render_credit_cents.zero?

      @applied_credit_cents = [ @order.user.render_credit_cents,
        @order.price_cents ].min

      # TODO: Make sure this happens in a DB transaction
      @order.user.render_credit_cents -= @applied_credit_cents
      @order.user.save
    end

    def stripe_session_params
      params = {
        mode: "payment",
        customer_email: customer_email_address,
        line_items: create_line_items,
        metadata: { order_id: @order.id.to_s },
        success_url: @order.success_url,
        cancel_url: @order.cancel_url,
      }
      if @applied_credit_cents.positive?
        params[:total_details]  = { amount_discount: @applied_credit_cents.fdiv(100) }
      end
      params
    end

    def create_line_items
      @order.items.map do |item|
        {
          price_data: {
            currency: "usd",
            unit_amount: item.project.price_cents,
            product_data: { name: item.project.blend_file },
          },
          quantity: 1,
        }
      end
    end

    def customer_email_address
      @order.user ? @order.user.email_address : @order.guest_email_address
    end
end
