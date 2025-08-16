class Project < ApplicationRecord
  STATES = %i[ created checking checked benchmarking benchmarked rendering rendered
    cancelled failed ].freeze
  EVENTS = %i[ start_checking start_benchmarking start_rendering finish cancel
    fail ].freeze

  include Uuidable
  include Statable

  belongs_to :upload
  has_many :blend_checks, class_name: "Project::BlendCheck"
  has_many :benchmarks, class_name: "Project::Benchmark"
  has_many :renders, class_name: "Project::Render"
  has_many :settings_revisions
  has_one :order_item

  delegate :user, to: :upload

  broadcasts_to ->(project) { :projects }

  validates :blend_file, presence: true

  after_create :start_checking

  def settings
    # TODO: Figure out cache invalidation for this one
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
    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end
end
