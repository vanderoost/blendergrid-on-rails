class Affiliate < ApplicationRecord
  belongs_to :user
  belongs_to :landing_page, optional: true
  has_many :affiliate_monthly_stats, dependent: :destroy

  validates :reward_percent,
    presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :reward_window_months,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 }
  validates :landing_page, presence: true, if: -> { referral_code.blank? }
  validates :referral_code, presence: true, if: -> { landing_page_id.blank? }

  before_validation :set_referral_code, unless: :landing_page_id?, on: :create

  def has_referrals?
    if landing_page_id?
      User.where(page_variant_id: landing_page.page_variant_ids).exists?
    else
      User.where(referring_affiliate_id: id).exists?
    end
  end

  private
    def set_referral_code
      loop do
        self.referral_code = SecureRandom.alphanumeric(8).downcase
        break unless Affiliate.exists?(referral_code: referral_code)
      end
    end
end
