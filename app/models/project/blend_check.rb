class Project::BlendCheck < ApplicationRecord
  include Workflowable

  belongs_to :project

  def owner = project

  def render_type
    RenderType.new(name: :image)
  end

  def make_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    {
      workflow_id: workflow.uuid,
      deadline:    Time.current.to_i,
      files: {
        input: {
          scripts: "s3://blendergrid-blender-scripts/#{swarm_engine_env}",
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}",
        },
      output: "s3://#{bucket}/projects/#{project.uuid}/jsons",
      logs: "s3://#{bucket}/projects/#{project.uuid}/logs",
      },
      executions: [
        {
          job_id: "integrity-check",
          command: [
            "/tmp/project/#{project.blend_filepath}",
            "--python", "/tmp/scripts/integrity_check.py",
            "--",
            "--output-dir", "/tmp/output",
          ],
          image: Rails.env.production? ? {
            command: [ "python", "/tmp/scripts/get_blender_image.py",
              "/tmp/project/#{project.blend_filepath}" ],
          } : "blendergrid/blender:latest",
        },
      ],
      metadata: { type: "integrity-check", created_by: "blendergrid-on-rails" },
    }
  end

  def handle_completion
    current_scene_name = workflow.result&.dig("settings", "scene_name")
    puts "CURRENT SCENE NAME: #{current_scene_name}"
    workflow.result&.dig("settings", "scenes")&.each do |scene_name, settings|
      puts "SCENE NAME: #{scene_name}"
      blender_scene = project.blender_scenes.find_or_initialize_by(name: scene_name)

      puts "SETTINGS: #{settings}"
      sliced_settings = settings.slice(*BlenderScene.column_names)
      puts "SLICED SETTINGS: #{sliced_settings}"

      blender_scene.update(sliced_settings)
      project.current_blender_scene = blender_scene if scene_name == current_scene_name
    end
    project.finish_checking
  end
end
