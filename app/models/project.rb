class Project < ApplicationRecord
  belongs_to :project_source
  has_many :workflows

  enum :status,
    [ :started,  :waiting, :rendering, :finished, :failed ],
    default: :started

  broadcasts_to ->(p) { [ p.project_source, :projects ] },
    partial: "projects/project",
    inserts_by: :prepend
end
