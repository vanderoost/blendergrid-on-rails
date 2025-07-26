class Upload < ApplicationRecord
  include Uuidable

  belongs_to :user, optional: true
  has_many_attached :files
  has_many :projects

  after_create :find_blend_filepaths

  scope :from_session, ->(session) { where(uuid: Array(session[:upload_uuids])) }

  def new_project_batch(blend_filepaths)
    ProjectBatch.new(upload: self, blend_filepaths:)
  end

  private
    def find_blend_filepaths
      self.blend_filepaths = files.select { |file|
        file.blob.filename.extension == "blend"
      }.map { |file| file.blob.filename.to_s }
      save!
      # TODO: If someone uploads a directory, make sure the relative file paths are
      # preserved.
      # TODO: Handle .zip files by looking inside the contents (in background jobs)
    end
end
