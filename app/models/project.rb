class Project < ApplicationRecord
  include Uuidable

  belongs_to :upload
  has_one :check
  has_one :quote
  has_one :render

  after_create :create_check

  scope :from_session, ->(session) {
    joins(:upload).merge(Upload.from_session(session))
  }

  # TODO: Add state machine
  def status
    if quote&.workflow.present?
      "price-calculation-#{quote.status}"
    elsif check&.workflow.present?
      "integrity-check-#{check.status}"
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
      project.check&.settings,
      project.quote&.settings
      # project.render&.settings
    ])
  end

  def self.for_sample(project)
    new(snapshots: [ project.quote&.sample_settings ])
  end
end
