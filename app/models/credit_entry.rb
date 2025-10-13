class CreditEntry < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  enum :reason, %i[ old_balance topup pay_order refund ].index_with(&:to_s)

  after_create :update_user_render_credit

  private
    def update_user_render_credit
      user.render_credit_cents += amount_cents
      user.save
    end
end
