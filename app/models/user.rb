class User < ApplicationRecord
  has_secure_password validations: false # Allow email-only users to reduce friction
  has_many :sessions, dependent: :destroy
  has_many :projects, through: :project_sources

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
