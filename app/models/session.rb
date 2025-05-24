class Session < ApplicationRecord
  belongs_to :user
  has_many :projects
  has_many :uploads
end
