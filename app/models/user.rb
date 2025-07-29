class User < ApplicationRecord
  include EmailAddressVerification

  has_secure_password validations: false
  has_email_address_verification

  generates_token_for :session, expires_in: 2.days

  has_many :sessions, dependent: :destroy
  has_many :uploads
  has_many :projects, through: :uploads

  normalizes :email_address, with: ->(e) { e.strip.downcase if e }
  normalizes :guest_email_address, with: ->(e) { e.strip.downcase if e }

  validates :email_address, uniqueness: { case_sensitive: false, allow_nil: true }

  def registered?
    email_address.present? && password_digest.present?
  end

  def guest?
    email_address.blank? && guest_email_address.present?
  end

  def unidentified?
    email_address.blank? && guest_email_address.blank?
  end

  def generate_magic_projects_url
    app.projects_url(session_token: generate_token_for(:session))
  end
end
