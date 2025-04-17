class ProjectSource < ApplicationRecord
  belongs_to :user
  has_many :projects
  has_many_attached :attachments

  accepts_nested_attributes_for :projects
end
