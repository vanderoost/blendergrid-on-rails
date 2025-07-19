class Project < ApplicationRecord
  include Uuidentifiable

  belongs_to :upload
  has_one :integrity_check

  after_create :create_integrity_check
end
