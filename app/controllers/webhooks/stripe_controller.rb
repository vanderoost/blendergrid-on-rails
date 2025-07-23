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

      project = Project.find_by(uuid: session.metadata["project_uuid"])
      return unless project
      return if project.render.present?

      logger.info "STARTING RENDER FOR PROJECT: #{project.inspect}"
      project.create_render
    end
end
