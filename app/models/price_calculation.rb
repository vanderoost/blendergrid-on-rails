class PriceCalculation < ApplicationRecord
  include Workflowable

  belongs_to :project

  def make_workflow_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    # TODO: Use real data
    sample_res_x = 960
    sample_res_y = 540
    sample_spp = 64
    sample_frames = [ 1, 5, 10 ]
    blender_version = "latest"

    {
      workflow_id: workflow.uuid,
      deadline:    10.minutes.from_now.to_i,
      files: {
        input: {
          scripts: "s3://blendergrid-blender-scripts/#{swarm_engine_env}",
          settings: "s3://#{bucket}/projects/#{project.uuid}/jsons",
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}"
        },
      output: "s3://#{bucket}/projects/#{project.uuid}/output",
      logs: "s3://#{bucket}/projects/#{project.uuid}/logs"
      },
      executions: [
          {
            job_id:  "sample-frame-$frame",
            command: [
              "/tmp/project/#{project.main_blend_file}",
              "--python",
              "/tmp/scripts/init.py",
              "--python",
              "/tmp/scripts/sample.py",
              "-o",
              "/tmp/output/sample-frames/sample-",
              "-f",
              "$frame",
              "--",
              "--resolution-width",
              sample_res_x.to_s,
              "--resolution-height",
              sample_res_y.to_s,
              "--cycles-samples",
              sample_spp.to_s,
              "--settings-file",
              "/tmp/settings/integrity-check.json",
              "--project-dir",
              "/tmp/project"
            ],
            parameters: {
                frame: sample_frames
            },
            image: "blendergrid/blender:#{blender_version}"
          }
      ],
      metadata: {
        type: "price-calculation",
        created_by: "blendergrid-on-rails",
        project_uuid: project.uuid
      }
    }
  end

  def handle_result(result)
    self.node_type = result.dig("node_type")
    self.timing = result.dig("timing")
    save!
  end
end
