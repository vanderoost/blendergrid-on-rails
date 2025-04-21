class Project < ApplicationRecord
  belongs_to :project_source
  has_many :workflows

  enum :status,
    [ :started,  :waiting, :rendering, :finished, :failed ],
    default: :started

  broadcasts_to ->(project) { [ project.project_source, :projects ] },
    target: ->(project) { dom_id(project) },
    inserts_by: :prepend,
    partial: "projects/project"
end
