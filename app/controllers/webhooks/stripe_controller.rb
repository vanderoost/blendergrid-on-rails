class Webhooks::StripeController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token # To turn off CSRF protection

  def handle
    Rails.logger.debug "Stripe Webhook Received"

    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    event = nil

    # Verify webhook signature and extract the event
    # See https://stripe.com/docs/webhooks#verify-events for more information.
    begin
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      payload = request.body.read
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid payload: " + e.message
      return head 400
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Invalid signature: " + e.message
      return head 400
    end

    Rails.logger.info "Webhook event received: " + event.inspect

    if event["type"] == "checkout.session.completed" ||
    event["type"] == "checkout.session.async_payment_succeeded"
      fulfill_checkout(event["data"]["object"]["id"])
    end
  end

  private
    def fulfill_checkout(checkout_session_id)
      Rails.logger.info "Fulfilling checkout session: " + checkout_session_id

      projects = Project.where(stripe_session_id: checkout_session_id)

      Rails.logger.info "Starting render for #{projects.count} projects"

      projects.each do |project|
        Rails.logger.info "Rendering project: " + project.uuid
        project.start_render
      end
    end
end
