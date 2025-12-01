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
    scripts_bucket = Rails.configuration.swarm_engine[:scripts_bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    {
      workflow_id: workflow.uuid,
      deadline: Time.current.to_i,
      files: {
        input: {
          scripts: "s3://#{scripts_bucket}/#{swarm_engine_env}",
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
            "--project-dir", "/tmp/project",
            "--output-dir", "/tmp/output",
          ],
          image: Rails.env.production? ? {
            command: [
              "python",
              "/tmp/s3/blendergrid-blender-scripts/#{swarm_engine_env}/"\
                "get_blender_image.py",
              "/tmp/s3/#{project.bucket_name}/projects/#{project.uuid}/"\
                "input/#{project.blend_filepath}",
              "/tmp/s3/#{bucket}/uploads/#{project.upload.uuid}/"\
                "#{project.blend_filepath}",
            ],
          } : "blendergrid/blender:latest",
        },
      ],
      metadata: { type: "integrity-check", created_by: "blendergrid-on-rails" },
    }
  end

  def handle_completion
    scenes_data = workflow.result&.dig("settings", "scenes")

    if scenes_data.blank?
      Rails.logger.error(
        "BlendCheck#handle_completion: Missing scenes data! " \
        "Project: #{project.id}, Workflow: #{workflow.id}, " \
        "Result present: #{workflow.result.present?}, " \
        "Result keys: #{workflow.result&.keys}, " \
        "Settings keys: #{workflow.result&.dig('settings')&.keys}"
      )
    end

    current_scene_name = workflow.result&.dig("settings", "scene_name")
    scenes_data&.each do |scene_name, settings|
      blender_scene = project.blender_scenes.find_or_initialize_by(name: scene_name)
      blender_scene.update(settings.slice(*BlenderScene.column_names))
      project.current_blender_scene = blender_scene if scene_name == current_scene_name
    end
    project.finish_checking
  end
end
