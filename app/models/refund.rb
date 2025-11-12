class Refund < ApplicationRecord
  belongs_to :order_item, class_name: "Order::Item"
  has_many :credit_entries

  delegate :order, to: :order_item
  delegate :project, to: :order_item

  after_create :maybe_refund_stripe

  def refund_stripe
    refund = Stripe::Refund.create({
      payment_intent: order.stripe_payment_intent_id,
      amount: amount_cents,
    })

    self.stripe_refund_id = refund.id
    save
  end

  private
    # TODO: Rethink this logic
    def maybe_refund_stripe
      if order.user.present?
        puts "DELAYING REFUND WITH CREDIT"
        return
      end

      refund_stripe
    end
end
