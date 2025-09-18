# Form object, creating multiple Projects from .blend files out of a single Upload
class Project::Intake
  HUMANIZED_ATTRIBUTES = { blend_filepaths: "The .blend file selection" }

  # TODO: Figure out what the difference is between ::Model and ::API
  # https://guides.rubyonrails.org/active_model_basics.html#model
  include ActiveModel::Model

  attr_accessor :upload, :blend_filepaths

  validates :upload, presence: true
  validates :blend_filepaths, presence: true

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def blend_filepaths=(val)
    @blend_filepaths = Array(val).reject(&:blank?)
  end

  def save
    valid? &&
    blend_filepaths.map { |bf| upload.projects.create(blend_filepath: bf) }.all?
  end
end
