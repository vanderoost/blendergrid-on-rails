class Project < ApplicationRecord
  STATES = %i[
    uploaded
    checking
    checked
    quoting
    quoted
    rendering
    rendered
    finished
    cancelled
    failed].freeze
  ACTIONS = %i[start_checking start_quoting start_rendering finish cancel fail].freeze

  include Uuidable
  include Statusable

  belongs_to :upload
  has_many :checks
  has_many :quotes
  has_many :renders

  broadcasts_to ->(project) { :projects }

  after_create :start_check

  scope :from_session, ->(session) {
    joins(:upload).merge(Upload.from_session(session))
  }

  def settings
    @settings ||= Project::Settings.for_project(self)
  end

  def sample_settings
    @sample_settings ||= Project::Settings.for_sample(self)
  end

  def check = latest(:check)
  def quote = latest(:quote)
  def render = latest(:render)

  private
    def start_check
      checks.create
    end

    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end
end

class Project::Settings
  def self.for_project(project)
    new(snapshots: [
      project.checks.last&.settings,
      project.quotes.last&.settings,
      project.renders.last&.settings
    ])
  end

  def self.for_sample(project)
    new(snapshots: [ project.quotes.last&.sample_settings ])
  end
end
