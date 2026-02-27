# Form object, take multiple Projects and turn it into an Order to be fulfilled
# On fulfillment, each Project gets a Render
class Order < ApplicationRecord
  MIN_ORDER_CENTS = 75

  include Trackable

  has_many :items, class_name: "Order::Item"
  has_many :projects, through: :items
  belongs_to :user, optional: true

  attr_accessor :project_uuids, :success_url, :cancel_url, :redirect_url

  after_create :checkout
  after_update :maybe_create_referral_affiliate_for_user,
    if: -> { saved_change_to_stripe_payment_intent_id? }

  # TODO: Add validations

  def fulfill
    apply_render_credit
    projects.each(&:start_rendering)
  end

  def price_cents
    projects.sum(&:price_cents)
  end

  private

  def maybe_create_referral_affiliate_for_user
    user&.maybe_create_referral_affiliate
  end

  def checkout
    create_order_items

    # If the cash_cents is 0, immediately fulfill the order with render credit
    if self.cash_cents.zero?
      fulfill
    # Otherwise start a Stripe checkout session
    else
      start_checkout_session
    end
    save
  end

  def create_order_items
    # TODO: Optimize this. Right now, we're persisting the Order (to get an ID) then
    # we can create OrderItems associated with this Order (by ID) and then we use
    # those items to create the Stripe line items for the Stripe checkout session.
    # Instead, we should use a before_create callback on Order. We then create all
    # line items in memory first, use them for the Stripe checkout session, put the
    # Stripe related propertiies on the Order, and then persist the Order. Then
    # persist the OrderItems

    projects = project_uuids.map do |uuid|
      project = Project.find_by(uuid: uuid)
      raise "Project '#{uuid}' not found" if project.nil?
      project
    end
    raise "Order has no projects" if projects.empty?
    total_cents = projects.sum(&:price_cents)

    user_credit_cents = user&.render_credit_cents || 0

    # Use as much credit as possible
    self.credit_cents = [ total_cents, user_credit_cents ].min
    self.cash_cents = total_cents - self.credit_cents

    raise "Order cash is negative" if self.cash_cents.negative?
    raise "Order credit is negative" if self.credit_cents.negative?

    # Ensure we use a minimum order amount
    if (1...MIN_ORDER_CENTS).include?(self.cash_cents)
      self.cash_cents = MIN_ORDER_CENTS
      self.credit_cents = total_cents - self.cash_cents
    end

    projects.each do |project|
      if self.credit_cents.zero?
        item_cash_cents = project.price_cents
        item_credit_cents = 0
      elsif self.cash_cents.zero?
        item_cash_cents = 0
        item_credit_cents = project.price_cents
      else
        item_cash_cents = (
          project.price_cents * self.cash_cents.fdiv(total_cents)
        ).ceil # Ceil to make sure we don't end up using too little cash for Stripe
        item_credit_cents = project.price_cents - item_cash_cents
      end

      items.create(
        project: project,
        cash_cents: item_cash_cents,
        credit_cents: item_credit_cents,
        preferences: {
          deadline_hours: project.tweaks_deadline_hours,
          resolution_percentage: project.tweaks_resolution_percentage,
          sampling_max_samples: project.tweaks_sampling_max_samples,
        },
      )
    end
  end

  def start_checkout_session
    stripe_session = Stripe::Checkout::Session.create({
      mode: "payment",
      customer_email: customer_email_address,
      line_items: create_line_items,
      metadata: { order_id: id.to_s },
      success_url: success_url,
      cancel_url: cancel_url,
    })
    self.stripe_session_id = stripe_session.id
    self.redirect_url = stripe_session.url
  end

  def create_line_items
    items.map do |item|
      product_data = { name: item.project.name }
      if item.credit_cents.positive?
        product_data[:description] = "Using #{helpers.number_to_currency(
          item.credit_cents.fdiv(100)
        )} of render credit"
      end
      {
          price_data: {
          currency: "usd",
          unit_amount: item.cash_cents,
          product_data: product_data,
        },
        quantity: 1,
      }
    end
  end

  def customer_email_address
    user ? user.email_address : guest_email_address
  end

  def apply_render_credit
    return unless credit_cents.positive?

    CreditEntry.create(
      user: user,
      amount_cents: -credit_cents,
      reason: :pay_order,
    )
  end

  # TODO: Is this the right location for this?
  def helpers
    ActionController::Base.helpers
  end
end
