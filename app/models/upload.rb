class Upload < ApplicationRecord
  include Uuidable

  has_one_attached :source_file
  has_many :projects

  after_create :create_project

  scope :from_session, ->(session) { where(uuid: Array(session[:upload_uuids])) }

  private
    def create_project
      project = projects.create(main_blend_file: source_file.blob.filename)
    end
end
