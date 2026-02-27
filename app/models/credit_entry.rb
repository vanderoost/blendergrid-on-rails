class CreditEntry < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true
  belongs_to :refund, optional: true

  enum :reason, %i[ old_balance gift topup pay_order credit_refund delayed_cash_refund
    reversed_cash_refund ].index_with(&:to_s)

  after_create :update_user_render_credit
  after_create :maybe_create_referral_affiliate_for_user, if: :topup?

  private
    def maybe_create_referral_affiliate_for_user
      user.maybe_create_referral_affiliate
    end

    def update_user_render_credit
      user.render_credit_cents += amount_cents
      user.save
    end
end
