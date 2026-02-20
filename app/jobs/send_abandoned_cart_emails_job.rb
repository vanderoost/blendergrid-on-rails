class SendAbandonedCartEmailsJob < ApplicationJob
  ABANDONMENT_MIN_AGE    = 1.hour
  ABANDONMENT_MAX_AGE    = 3.days
  CART_RATE_LIMIT_PERIOD = 30.days
  ANY_EMAIL_COOLDOWN     = 2.hours

  queue_as :default

  def perform
    abandoned_orders.group_by { |o| email_address_for(o) }.each do |email, orders|
      next if email.blank?
      next if already_rendered?(orders.first, email)
      next if cart_email_sent_recently?(email)
      next if any_email_sent_recently?(email)

      OrderMailer.abandoned_cart(orders.first).deliver_later
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
      have_paid_orders = order.user.orders.where.not(stripe_payment_intent_id: nil)
        .exists?
      have_paid_orders
    else
      have_paid_orders = Order.where(guest_email_address: email_address)
           .where.not(stripe_payment_intent_id: nil)
           .exists?
      have_paid_orders
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
