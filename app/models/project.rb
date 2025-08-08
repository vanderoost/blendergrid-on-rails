class Project < ApplicationRecord
  STATES = %i[
    uploaded
    checking
    checked
    benchmarking
    benchmarked
    rendering
    rendered
    cancelled
    failed].freeze
  ACTIONS = %i[start_checking start_benchmarking start_rendering finish cancel fail].freeze

  include Uuidable
  include Statusable

  belongs_to :upload
  has_many :checks, class_name: "Project::Check"
  has_many :benchmarks, class_name: "Project::Benchmark"
  has_many :renders, class_name: "Project::Render"
  has_many :settings_revisions
  has_one :order_item

  delegate :user, to: :upload

  broadcasts_to ->(project) { :projects }

  after_create :start_check

  def settings
    # @settings ||= Project::ResolvedSettings.new(
    #   revisions: settings_revisions.map(&:settings)
    # )
    Project::ResolvedSettings.new(revisions: settings_revisions.map(&:settings))
  end
  def benchmark_settings
    Project::ResolvedSettings.new(
      revisions: settings_revisions.map(&:settings) + [ benchmark.sample_settings ]
    )
  end

  def price_cents
    Pricing::Calculation.new(self).price_cents
  end

  def check = latest(:check)
  def benchmark = latest(:benchmark)
  def render = latest(:render)

  private
    def start_check
      checks.create
    end

    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end
end
