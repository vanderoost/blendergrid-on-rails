class IntegrityCheck < ApplicationRecord
  include Workflowable

  belongs_to :project

  def make_workflow_start_message
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
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}"
        },
      output: "s3://#{bucket}/projects/#{project.uuid}/jsons",
      logs: "s3://#{bucket}/projects/#{project.uuid}/logs"
      },
      executions: [
        {
          job_id: "integrity-check",
          command: [
            "/tmp/project/#{project.main_blend_file}",
            "--python", "/tmp/scripts/integrity_check.py",
            "--",
            "--output-dir", "/tmp/output"
          ],
          image: Rails.env.production? ? {
            command: [ "python", "/tmp/scripts/get_blender_image.py",
            "/tmp/project/#{project.main_blend_file}" ]
          } : "blendergrid/blender:latest"
        }
      ],
      metadata: { type: "integrity-check", created_by: "blendergrid-on-rails" }
    }
  end

  def handle_result(result)
    self.stats = result.dig("stats")
    self.settings = result.dig("settings")
    save!
  end
end
