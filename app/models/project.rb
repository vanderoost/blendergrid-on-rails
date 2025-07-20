class Project < ApplicationRecord
  include Uuidable

  belongs_to :upload
  has_one :integrity_check
  has_one :price_calculation

  after_create :create_integrity_check

  scope :from_session, ->(session) {
    joins(:upload).merge(Upload.from_session(session))
  }

  def status
    if price_calculation&.workflow.present?
      "price-calculation-#{price_calculation.status}"
    elsif integrity_check&.workflow.present?
      "integrity-check-#{integrity_check.status}"
    else
      "uploaded"
    end
  end
end
