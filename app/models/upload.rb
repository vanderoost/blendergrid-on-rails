class Upload < ApplicationRecord
  has_one_attached :source_file
  has_many :projects

  after_create :create_project

  private
    def create_project
      project = projects.create(
        uuid: SecureRandom.uuid,
        main_blend_file: source_file.blob.filename,
      )
    end
end
