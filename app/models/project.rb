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

  delegate :user, to: :upload

  broadcasts_to ->(project) { :projects }

  after_create :start_check
  after_create :send_test_email

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

    def send_test_email
      ProjectMailer.project_created(self).deliver_later
    end

    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end
end

class Project::Settings
  def self.for_project(project)
    snapshots = [
      project.checks.last&.workflow&.settings,
      project.quotes.last&.workflow&.settings,
      project.renders.last&.workflow&.settings
    ].compact

    new(data: deep_merge_snapshots(snapshots))
  end

  def self.for_sample(project)
    data = project.quotes.last&.sample_settings || {}
    new(data: data)
  end

  def self.deep_merge_snapshots(snapshots)
    snapshots
      .map { |h| h.deep_symbolize_keys }
      .reduce({}) { |acc, h| acc.deep_merge(h) }
  end
  private_class_method :deep_merge_snapshots
end
