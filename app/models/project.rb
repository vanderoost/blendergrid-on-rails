class Project < ApplicationRecord
  include Project::StateMachine

  belongs_to :project_source
  has_many :workflows

  enum :status, [
      :uploaded,
      :checking_integrity,
      :checked,
      :calculating_price,
      :waiting,
      :rendering,
      :finished,
      :cancelled,
      :failed,
      :deleted
    ], default: :uploaded

  attribute :settings, :json, default: {}
  attribute :stats, :json,  default: {}

  STAGES = [ :uploaded, :waiting, :rendering, :finished, :stopped, :deleted ].freeze
  def stage
    return :uploaded if status.to_sym.in? [ :uploaded, :checking_integrity, :checked ]
    return :waiting if status.to_sym.in? [
      :calculating_price, :waiting, :payment_pending ]
    return :stopped if status.to_sym.in? [ :cancelled, :failed ]
    status.to_sym
  end

  def is_processing
    status.to_sym.in? [ :checking_integrity, :calculating_price, :rendering ]
  end

  def to_param
    uuid
  end

  def price
    return 100 # TODO: Calculate real price

    price_calc_wf = workflows.where(job_type: :price_calculation).first
    return nil unless price_calc_wf

    price_calc_wf.timing
  end

  broadcasts_to ->(project) { [ project.project_source, project.stage, :projects ] },
    partial: "projects/project",
    target: ->(project) { "stage_#{project.stage}" },
    inserts_by: :prepend

  delegate :user, to: :project_source, allow_nil: true
end
