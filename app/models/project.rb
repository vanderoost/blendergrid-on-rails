class Project < ApplicationRecord
  include Uuidable

  belongs_to :upload
  has_one :integrity_check
  has_one :price_calculation

  after_create :create_integrity_check

  scope :from_session, ->(session) {
    joins(:upload).merge(Upload.from_session(session))
  }

  # TODO: Add state machine
  def status
    if price_calculation&.workflow.present?
      "price-calculation-#{price_calculation.status}"
    elsif integrity_check&.workflow.present?
      "integrity-check-#{integrity_check.status}"
    else
      "uploaded"
    end
  end

  def settings
    @settings ||= Project::Settings.for_project(self)
  end

  def sample_settings
    @sample_settings ||= Project::Settings.for_sample(self)
  end
end

class Project::Settings
  def self.for_project(project)
    new(snapshots: [
      project.integrity_check&.settings,
      project.price_calculation&.settings
      # project.render&.settings
    ])
  end

  def self.for_sample(project)
    new(snapshots: [ project.price_calculation&.sample_settings ])
  end
end
