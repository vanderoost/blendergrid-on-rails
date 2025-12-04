class Affiliate < ApplicationRecord
  belongs_to :user
  belongs_to :landing_page
  has_many :affiliate_monthly_stats, dependent: :destroy

  validates :commission_percent,
    presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :reward_window_months,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 }
end
