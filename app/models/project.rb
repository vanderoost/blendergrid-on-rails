class Project < ApplicationRecord
  belongs_to :project_source
  has_many :workflows

  enum :status,
    [ :started,  :waiting, :rendering, :finished, :failed ],
    default: :started
end
