class Project::Duplicate
  include ActiveModel::Model

  attr_accessor :project

  def save
    new_project = project.dup
    new_project.uuid = SecureRandom.uuid
    new_project.name = new_name
    new_project.stage_updated_at = Time.now

    project.blender_scenes.each do |scene|
      new_scene = scene.dup
      new_scene.save

      if scene.id == project.current_blender_scene_id
        new_project.current_blender_scene = new_scene
      end
    end

    new_project.save
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
