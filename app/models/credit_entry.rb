class CreditEntry < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  enum :reason, %i[ old_balance topup pay_order refund ].index_with(&:to_s)
end
