class User < ApplicationRecord
  include EmailAddressVerifyable

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

  normalizes :email_address, with: ->(e) { e.strip.downcase if e }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }

  def first_name
    name.split(" ").first&.titleize || email_address.split("@").first
  end
end
