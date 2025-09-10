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

  normalizes :email_address, with: ->(e) { e.strip.downcase if e }

  validates :email_address, uniqueness: { case_sensitive: false }
end
