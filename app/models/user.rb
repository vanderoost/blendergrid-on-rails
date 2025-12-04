class User < ApplicationRecord
  include EmailAddressVerifyable
  include Trackable

  has_secure_password
  has_email_address_verification

  generates_token_for :session, expires_in: 2.days

  has_many :sessions, dependent: :destroy
  has_many :uploads
  has_many :projects, through: :uploads
  has_many :orders
  has_many :articles
  has_many :credit_entries
  has_many :requests
  has_many :events, through: :requests
  belongs_to :page_variant, optional: true
  has_one :affiliate, dependent: :destroy

  after_create :attribute_page_variant_later

  scope :from_page_variant, ->(variant) {
    where(page_variant: variant)
  }

  normalizes :email_address, with: ->(e) { e.strip.downcase if e }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }

  def first_name
    name&.split(" ")&.first&.titleize || email_address.split("@").first
  end

  def slug
    name&.parameterize
  end

  private
    def attribute_page_variant_later
      AttributePageVariantJob.set(wait: 2.minutes).perform_later(self)
    end
end
