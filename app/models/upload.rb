class Upload < ApplicationRecord
  include Uuidable

  belongs_to :user, optional: true
  has_one_attached :source_file
  has_many :projects

  after_create :create_projects

  scope :from_session, ->(session) { where(uuid: Array(session[:upload_uuids])) }

  private
    def create_projects
      # TODO: Allow multiple projects per upload
      projects.create(main_blend_file: source_file.blob.filename)
    end
end
