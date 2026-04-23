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
    fetch_result_from_s3 if workflow.result.blank?
    project.finish_checking
  end

  private
    def fetch_result_from_s3
      stats_key = "projects/#{project.uuid}/jsons/stats.json"
      stats = JSON.parse(project.bucket.object(stats_key).get.body.read)
      settings_key = "projects/#{project.uuid}/jsons/settings.json"
      settings = JSON.parse(project.bucket.object(settings_key).get.body.read)
      workflow.update!(result: { stats: stats, settings: settings })
    rescue Aws::S3::Errors::NoSuchKey, JSON::ParserError => e
      Rails.logger.warn(
        "Blend check S3 fallback failed for project #{project.uuid}: #{e.message}"
      )
    end
end
