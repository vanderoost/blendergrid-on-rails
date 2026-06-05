class User < ApplicationRecord
  REFERRAL_AFFILIATE_MIN_SPENT_CENTS = 1000

  include EmailAddressVerifyable
  include Trackable

  has_secure_password
  has_email_address_verification

  generates_token_for :session, expires_in: 2.days

  generates_token_for :invite, expires_in: 30.days do
    password_salt&.last(10) # link self-destructs once they set their own password
  end

  has_many :sessions, dependent: :destroy
  has_many :uploads
  has_many :projects, through: :uploads
  has_many :orders
  has_many :articles
  has_many :credit_entries
  has_many :requests
  has_many :events, through: :requests
  belongs_to :page_variant, optional: true
  belongs_to :referring_affiliate, class_name: "Affiliate", optional: true
  has_one :affiliate, dependent: :destroy
  has_one :subscriber, dependent: :destroy

  scope :from_page_variant, ->(variant) {
    where(page_variant: variant)
  }

  normalizes :email_address, with: ->(e) { e.strip.downcase if e }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }

  after_create :attribute_page_variant_later
  after_create :create_or_promote_subscriber

  def sales_cents
    orders.where.not(stripe_payment_intent_id: nil).sum(:cash_cents) +
    credit_entries.where(reason: :topup).sum(:amount_cents)
  end

  def first_name
    name&.split(" ")&.first&.titleize || email_address.split("@").first
  end

  def slug
    name&.parameterize
  end

  def maybe_create_referral_affiliate
    return if affiliate.present?
    return unless sales_cents >= REFERRAL_AFFILIATE_MIN_SPENT_CENTS
    Affiliate.create!(user: self, reward_percent: 10, reward_window_months: 12)
  end

  private
    def attribute_page_variant_later
      AttributePageVariantJob.set(wait: 2.minutes).perform_later(self)
    end

    # Link a prior newsletter (guest) subscriber to this account if one matches the
    # email, otherwise start a fresh subscription. Keeps a single subscriber per user.
    def create_or_promote_subscriber
      guest = Subscriber.where(user_id: nil)
                        .find_by(guest_email_address: email_address)
      if guest
        guest.update!(user: self, guest_email_address: nil)
      else
        Subscriber.create!(user: self, source: "signup")
      end
    end
end
