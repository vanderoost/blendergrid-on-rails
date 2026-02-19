class SendAbandonedCartEmailsJob < ApplicationJob
  ABANDONMENT_MIN_AGE    = 1.hour
  ABANDONMENT_MAX_AGE    = 3.days
  CART_RATE_LIMIT_PERIOD = 30.days
  ANY_EMAIL_COOLDOWN     = 2.hours

  queue_as :default

  def perform
    abandoned_orders.each do |order|
      email_address = email_address_for(order)
      next if email_address.blank?
      next if already_rendered?(order, email_address)
      next if cart_email_sent_recently?(email_address)
      next if any_email_sent_recently?(email_address)

      OrderMailer.abandoned_cart(order).deliver_later
    end
  end

  private

  def abandoned_orders
    Order
      .where(stripe_payment_intent_id: nil)
      .where.not(stripe_session_id: nil)
      .where(cash_cents: 1..)
      .where(created_at: ABANDONMENT_MAX_AGE.ago..ABANDONMENT_MIN_AGE.ago)
      .includes(:user, projects: :upload)
  end

  def email_address_for(order)
    order.user&.email_address || order.guest_email_address
  end

  def already_rendered?(order, email_address)
    if order.user.present?
      order.user.orders.where.not(stripe_payment_intent_id: nil).exists?
    else
      Order.where(guest_email_address: email_address)
           .where.not(stripe_payment_intent_id: nil)
           .exists?
    end
  end

  def cart_email_sent_recently?(email_address)
    Email
      .where(
        email_address: email_address,
        mailer_class: "OrderMailer",
        action: "abandoned_cart",
      )
      .where(created_at: CART_RATE_LIMIT_PERIOD.ago..)
      .exists?
  end

  def any_email_sent_recently?(email_address)
    Email
      .where(email_address: email_address)
      .where(created_at: ANY_EMAIL_COOLDOWN.ago..)
      .exists?
  end
end
