class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :uploads
  has_many :projects, through: :uploads

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
end
