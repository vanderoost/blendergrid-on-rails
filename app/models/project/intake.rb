# Form object, creating multiple Projects from .blend files out of a single Upload
class Project::Intake
  # TODO: Figure out what the difference is between ::Model and ::API
  # https://guides.rubyonrails.org/active_model_basics.html#model
  include ActiveModel::Model

  attr_accessor :upload, :blend_files

  validates :upload, presence: true
  validates :blend_files, presence: true, length: { minimum: 1 }

  def blend_files=(val)
    @blend_files = Array(val).reject(&:blank?)
  end

  def save
    return false unless valid?

    is_success = true
    blend_files.each do |blend_file|
      is_success &&= upload.projects.create(blend_file: blend_file)
    end
    is_success
  end
end
