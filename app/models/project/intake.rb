# Form object, creating multiple Projects from .blend files out of a single Upload
class Project::Intake
  include ActiveModel::Model

  attr_accessor :upload, :blend_filepaths

  validates :upload, presence: true
  validates :blend_filepaths, length: { minimum: 1 }

  # def initialize(upload: nil, blend_filepaths: nil)
  #   @upload = upload
  #   @blend_filepaths = blend_filepaths
  # end

  def save
    return false unless valid?

    is_success = true
    blend_filepaths.each do |blend_filepath|
      is_success &&= upload.projects.create(blend_filepath:)
    end
    is_success
  end
end
