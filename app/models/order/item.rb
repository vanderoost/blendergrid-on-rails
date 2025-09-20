class Order::Item < ApplicationRecord
  belongs_to :order
  belongs_to :project

  delegate :user, to: :order, allow_nil: true

  def partial_refund(permil)
    permil ||= 0
    permil_to_refund = 1000 - permil
    refund_cents = price_cents * permil_to_refund.fdiv(1000)
    puts "REFUNDING #{permil_to_refund.fdiv(10)}% OF $#{refund_cents.fdiv(100)} ="\
      " $#{refund_cents.fdiv(100)}"

    if refund_cents.positive? and user.present?
      puts "TOPPING UP CREDIT"
      user.update(credit: user.credit + refund_cents)
    else
      puts "NO USER ASSOCIATED"
      # TODO: Figure out how to handle the refund wihtout a user
    end

    # First refund in Render credit only.
    # After a timeout, and the credit hasn't been used, do a full refund.
  end
end
