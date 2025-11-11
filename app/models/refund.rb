class Refund < ApplicationRecord
  belongs_to :project
  has_many :credit_entries
end
