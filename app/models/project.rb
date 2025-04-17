class Project < ApplicationRecord
  belongs_to :project_source
  belongs_to :user
end
