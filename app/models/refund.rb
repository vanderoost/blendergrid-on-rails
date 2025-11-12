class Refund < ApplicationRecord
  belongs_to :order_item, class_name: "Order::Item"
  has_many :credit_entries

  delegate :order, to: :order_item
  delegate :project, to: :order_item

  after_create :refund_stripe

  private
    # TODO: Do this in a background job
    def refund_stripe
      refund = Stripe::Refund.create({
        payment_intent: order.stripe_payment_intent_id,
        amount: amount_cents,
      })

      self.stripe_refund_id = refund.id
      save
    end
end
