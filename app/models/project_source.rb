class ProjectSource < ApplicationRecord
  has_many :projects
  accepts_nested_attributes_for :projects

  has_many_attached :attachments
end
