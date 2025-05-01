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
    return :waiting if status.to_sym.in? [ :calculating_price, :waiting ]
    return :stopped if status.to_sym.in? [ :cancelled, :failed ]
    status.to_sym
  end

  def is_processing
    status.to_sym.in? [ :checking_integrity, :calculating_price, :rendering ]
  end

  broadcasts_to ->(project) { [ project.project_source, project.stage, :projects ] },
    partial: "projects/project",
    target: ->(project) { "stage_#{project.stage}" },
    inserts_by: :prepend

  delegate :user, to: :project_source, allow_nil: true
end
