class CreditEntry < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  enum :reason, %i[ old_balance gift topup pay_order refund refund_to_credit
    refund_to_cash ].index_with(&:to_s)

  after_create :update_user_render_credit

  private
    def update_user_render_credit
      user.render_credit_cents += amount_cents
      user.save
    end
end
