class Project::Duplicate
  include ActiveModel::Model

  attr_accessor :project

  validates :project, presence: true
  validate :project_has_blend_check
  validate :project_has_blender_scenes

  def save
    return false unless valid?

    new_project = project.dup
    new_project.uuid = SecureRandom.uuid
    new_project.name = new_name
    new_project.stage_updated_at = Time.now
    new_project.status = :checked

    new_blend_check = project.blend_check.dup
    new_blend_check.update(project: new_project)

    new_workflow = project.blend_check.workflow.dup
    new_workflow.uuid = SecureRandom.uuid
    new_workflow.update(workflowable: new_blend_check)

    project.blender_scenes.each do |scene|
      new_scene = scene.dup
      new_scene.update(project: new_project)

      if scene.id == project.current_blender_scene_id
        new_project.current_blender_scene_id = new_scene.id
      end
    end

    raise "NEW PROJECT HAS NO CURRENT BLENDER SCENE" unless
      new_project.current_blender_scene

    new_project.save
  end

  def project_has_blend_check
    if %w[ created checking ].include?(project.status)
      errors.add(:base, "project has no finished blend check")
    end
  end

  def project_has_blender_scenes
    if project.blender_scenes.empty?
      puts "PROJECT HAS NO BLENDER SCENES"
      errors.add(:base, "project has no blender scenes")
    end
  end

  private
    def new_name
      re = /\.(\d{3})$/
      match = re.match(project.name)
      return "#{project.name}.001" unless match

      next_index = match.captures.first.to_i + 1
      "#{project.name.gsub(re, ".#{"%03d" % next_index}")}"

      # TODO: Handle duplicates with the same name (increment next_index until unique)
    end
end
