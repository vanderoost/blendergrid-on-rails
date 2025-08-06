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
      logger.info "SUCCESSFUL CHECKOUT"

      order = Order.find_by(stripe_session_id: session.id)
      return if order.nil?

      order.fulfill # TODO: Make this a fulfill_later job
      order.save
    end
end
