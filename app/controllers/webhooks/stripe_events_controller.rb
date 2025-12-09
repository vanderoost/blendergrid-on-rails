# TODO: Put this whole thing on a diet - Move logic into POROs
class Webhooks::StripeEventsController < Webhooks::BaseController
  def create
    logger.info "=== WEBHOOK RECEIVED ==="
    logger.info "Received webhook event type: #{event.type}"

    case event.type
    when "checkout.session.completed", "checkout.session.async_payment_succeeded"
      handle_successful_checkout event.data.object
    when "financial_connections.account.created"
      handle_payout_method_connected event.data.object
    when "v2.core.account[configuration.recipient].updated"
      # This fires when recipient configuration is completed with bank details
      logger.info "Handling recipient configuration update"
      handle_account_recipient_updated event
    else
      logger.info "UNHANDLED EVENT TYPE: #{event.type}"
    end

    head :ok

  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    render json: { error: e.message }, status: :bad_request
  end

  private
    def event
      @event ||= begin
        payload = request.body.read
        request.body.rewind

        # Try to parse as JSON first to check if it's a v2 event
        parsed_payload = JSON.parse(payload)

        # V2 events have object: "v2.core.event"
        if parsed_payload["object"] == "v2.core.event"
          # V2 thin events - use parse_event_notification
          request.body.rewind
          signature = request.env["HTTP_STRIPE_SIGNATURE"]
          secret = Rails.application.credentials.dig(:stripe, :webhook_secret_v2)

          client = Stripe::StripeClient.new(Stripe.api_key)
          client.parse_event_notification(payload, signature, secret)
        else
          # V1 events use the standard webhook verification
          request.body.rewind
          signature = request.env["HTTP_STRIPE_SIGNATURE"]
          secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
          Stripe::Webhook.construct_event(payload, signature, secret)
        end
      end
    end

    def handle_successful_checkout(session)
      if session.metadata["reason"] == "credit_topup"
        handle_credit_topup session
      else
        handle_order_fulfillment session
      end
    end

    def handle_credit_topup(session)
      user = User.find_by(email_address: session.customer_email)
      if user.nil?
        logger.error "User not found for email #{session.customer_email}"
        return
      end

      CreditEntry.create(
        user: user,
        amount_cents: session.amount_subtotal,
        reason: :topup,
      )
    end

    def handle_order_fulfillment(session)
      order = Order.find_by(stripe_session_id: session.id)
      return if order.nil?

      order.stripe_payment_intent_id = session.payment_intent
      order.cash_cents = session.amount_total
      order.fulfill # TODO: Make this a fulfill_later job
      order.save
    end

    def handle_payout_method_connected(financial_account)
      return if financial_account.nil?

      account_id = financial_account.account_holder.account
      affiliate = Affiliate.find_by(stripe_account_id: account_id)
      return if affiliate.nil?

      # Store payout method details and mark as onboarded
      affiliate.update(
        payout_method_details: {
          institution_name: financial_account.institution_name,
          last4: financial_account.last4,
          account_type: financial_account.subcategory,
          display_name: financial_account.display_name,
        },
        payout_onboarded_at: Time.current
      )
    end

    def handle_account_recipient_updated(event_notification)
      # event_notification is a Stripe EventNotification object
      # Fetch the related object (the account)
      begin
        account = event_notification.fetch_related_object
        return if account.nil?

        account_id = account.id
        logger.info "Processing recipient config for account: #{account_id}"

        affiliate = Affiliate.find_by(stripe_account_id: account_id)
        if affiliate.nil?
          logger.warn "No affiliate found for account: #{account_id}"
          return
        end

        # The v2.core.account[configuration.recipient].updated event fires
        # when recipient configuration is completed. Mark as onboarded.
        logger.info "Marking affiliate #{affiliate.id} as payout onboarded"

        affiliate.update(payout_onboarded_at: Time.current)

        logger.info "Successfully marked affiliate #{affiliate.id} as onboarded"
      rescue => e
        logger.error "Failed processing recipient update: #{e.message}"
        logger.error e.backtrace.first(5).join("\n")
      end
    end
end
