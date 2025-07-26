class ProjectBatch
  def initialize(upload:, blend_filepaths:)
    @upload = upload
    @blend_filepaths = blend_filepaths
  end

  def save
    is_success = true
    @blend_filepaths.each do |blend_filepath|
      is_success &&= @upload.projects.create(blend_filepath:)
    end
    is_success
  end
end
