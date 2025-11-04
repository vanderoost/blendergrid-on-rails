class Webhooks::StripeController < Webhooks::BaseController
  def handle
    case event.type
    when "checkout.session.completed", "checkout.session.async_payment_succeeded"
      handle_successful_checkout event.data.object
    else
      logger.info "UNHANDLED EVENT TYPE: #{event.type}"
    end

    head :ok

  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    render json: { error: e.message }, status: :bad_request
  end

  private
    def event
      payload = request.body.read
      signature = request.env["HTTP_STRIPE_SIGNATURE"]
      secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
      Stripe::Webhook.construct_event(payload, signature, secret)
    end

    def handle_successful_checkout(session)
      if session.metadata["reason"] == "credit_topup"
        handle_credit_topup session
      else
        handle_order_fulfillment session
      end
    end

    def handle_credit_topup(session)
      logger.info "CREDIT TOPUP: $#{session.amount_subtotal} for"\
        " #{session.customer_email}"

      user = User.find_by(email_address: session.customer_email)
      if user.nil?
        logger.error "User not found for email #{session.customer_email}"
        return
      end

      CreditEntry.create(user: user, amount_cents: session.amount_subtotal)
    end

    def handle_order_fulfillment(session)
      order = Order.find_by(stripe_session_id: session.id)
      return if order.nil?

      # TODO: Move this to the models, not controllers
      order.paid_cents = session.amount_total
      order.fulfill # TODO: Make this a fulfill_later job
      order.save
    end
end
