# TODO: Put this whole thing on a diet - Move logic into POROs
class Webhooks::StripeEventsController < Webhooks::BaseController
  def create
    logger.info "=== WEBHOOK RECEIVED ==="
    logger.info "Received webhook event type: #{event.type}"
    logger.info "Event object type: #{event.object}"

    case event.type
    when "checkout.session.completed", "checkout.session.async_payment_succeeded"
      handle_successful_checkout event.data.object
    when "financial_connections.account.created"
      handle_payout_method_connected event.data.object
    when "v2.core.account_link.returned"
      # v2 events have different structure - data is the object itself
      logger.info "Handling v2.core.account_link.returned event"
      handle_account_link_completed event.data
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

      # TODO: Move this into a model instead of controller
      order.stripe_payment_intent_id = session.payment_intent
      order.cash_cents = session.amount_total
      order.fulfill # TODO: Make this a fulfill_later job
      order.save
    end

    def handle_payout_method_connected(financial_account)
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

    def handle_account_link_completed(account_link_data)
      # v2 events pass data directly, not wrapped in an object
      account_id = account_link_data["account_id"] || account_link_data.account_id
      affiliate = Affiliate.find_by(stripe_account_id: account_id)
      return if affiliate.nil?

      # Fetch account details to get bank account info
      client = Stripe::StripeClient.new(Stripe.api_key)
      account = client.v2.core.accounts.retrieve(
        account_id,
        { include: [ "external_accounts" ] }
      )

      # Extract bank account details if available
      if account.external_accounts&.any?
        bank_account = account.external_accounts.first
        payout_details = {
          bank_name: bank_account.bank_name,
          last4: bank_account.last4,
          country: bank_account.country,
        }
      else
        payout_details = nil
      end

      # Mark the affiliate as onboarded and store bank details
      affiliate.update(
        payout_onboarded_at: Time.current,
        payout_method_details: payout_details
      )
    end
end
