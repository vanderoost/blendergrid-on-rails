class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :projects, through: :uploads

  # normalizes :email, with: ->(e) { e.strip.downcase }
  before_save { self.email = email.downcase }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)+\z/i
  validates :email, presence: true, length: { maximum: 254 },
    format: { with: VALID_EMAIL_REGEX }, uniqueness: true
  validates :name, length: { maximum: 255 }
  validates :password, presence: true, length: { minimum: 8 }
end
