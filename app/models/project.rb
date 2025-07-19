class Project < ApplicationRecord
  include Uuidable

  belongs_to :upload
  has_one :integrity_check

  after_create :create_integrity_check

  scope :from_session, ->(session) {
    joins(:upload).merge(Upload.from_session(session))
  }
end
