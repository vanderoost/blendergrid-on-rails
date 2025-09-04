class Project < ApplicationRecord
  STATES = %i[ created checking checked benchmarking benchmarked rendering rendered
    cancelled failed ].freeze
  EVENTS = %i[ start_checking start_benchmarking start_rendering finish_checking
    finish_benchmarking finish_rendering cancel fail ].freeze

  include Statable
  include Uuidable

  belongs_to :upload
  has_many :blend_checks, class_name: "Project::BlendCheck"
  has_many :benchmarks, class_name: "Project::Benchmark"
  has_many :renders, class_name: "Project::Render"
  has_one :order_item, class_name: "Order::Item"

  delegate :user, to: :upload

  broadcasts_to ->(project) { :projects }

  validates :blend_file, presence: true

  after_create :start_checking

  def settings(override: nil)
    Project::ResolvedSettings.new(revisions: [
      blend_check&.settings,
      benchmark&.settings,
      order_item&.settings,
      override,
    ])
  end

  def benchmark_settings
    settings(override: benchmark&.sample_settings)
  end

  def price_cents(override_settings: nil)
    Pricing::Calculation.new(
      settings: settings(override: override_settings),
      benchmark_settings: benchmark_settings,
      workflow: self.benchmark.workflow
    ).price_cents
  end

  def blend_check = latest(:blend_check)
  def benchmark = latest(:benchmark)
  def render = latest(:render)

  private
    def latest(model_sym)
      public_send(model_sym.to_s.pluralize).last
    end
end
