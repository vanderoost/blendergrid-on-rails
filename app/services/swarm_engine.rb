module SwarmEngine
  TOPIC_PREFIX = "external".freeze

  class << self
    def publish_integrity_check(workflow)
      project = workflow.project
      payload = build_integrity_check_payload(project, workflow.uuid)

      publish("workflow_started", payload)
    end

    def publish_price_calculation(workflow)
      project = workflow.project
      payload = build_price_calculation_payload(project, workflow.uuid)

      publish("workflow_started", payload)
    end

    private

    def publish(event_type, message_hash)
      topic_arn = arn_for(env_topic)

      Rails.logger.info "Publishing #{event_type} to #{topic_arn}"

      AwsClients.sns.publish(
        topic_arn: topic_arn,
        message:   message_hash.to_json,
        message_attributes: {
          event_type: { data_type: "String", string_value: event_type }
        }
      )
    end

    def env_topic
      "#{TOPIC_PREFIX}-#{Rails.application.credentials.dig(:swarm_engine, :env)}-topic"
    end

    def arn_for(topic)
      acct = Rails.application.credentials.dig(:aws, :account_id)
      "arn:aws:sns:us-east-1:#{acct}:#{topic}"
    end

    def build_integrity_check_payload(project, workflow_uuid)
      bucket      = Rails.application.credentials.dig(:swarm_engine, :bucket)
      swarm_env   = Rails.application.credentials.dig(:swarm_engine, :env)

      {
        workflow_id: workflow_uuid,
        deadline:    Time.current.to_i,
        files: {
          input: {
            scripts:  "s3://blendergrid-blender-scripts/#{swarm_env}",
            project:  "s3://#{bucket}/project-sources/#{project.project_source.uuid}"
          },
          output: "s3://#{bucket}/projects/#{project.uuid}/jsons",
          logs:   "s3://#{bucket}/projects/#{project.uuid}/logs"
        },
        executions: [
          {
            job_id:  "integrity-check",
            command: [
              "$input_dir/project/#{project.main_blend_file}",
              "--python", "$input_dir/scripts/integrity_check.py",
              "--", "--output-dir", "$output_dir"
            ],
            image: Rails.env.production? ? {
              command: [ "python",
                        "$input_dir/scripts/get_blender_image.py",
                        "$input_dir/project/#{project.main_blend_file}" ]
            } : "blendergrid/blender:latest"
          }
        ],
        metadata: { type: "integrity-check", created_by: "blendergrid-on-rails" }
      }
    end

    def build_price_calculation_payload(project, workflow_uuid)
      bucket      = Rails.application.credentials.dig(:swarm_engine, :bucket)
      swarm_env   = Rails.application.credentials.dig(:swarm_engine, :env)

      # orig_res_x = project.settings.output.format.resolution_x
      # orig_res_y = project.settings.output.format.resolution_y
      # orig_spp = project.settings.render.sampling.max_samples
      # frame_range_start = project.settings.output.frame_range.start
      # frame_range_end = project.settings.output.frame_range.end
      # frame_range_step = project.settings.output.frame_range.end

      sample_res_x = 1280
      sample_res_y = 720
      sample_spp = 48
      sample_frames = [ 0, 50, 100 ]
      blender_version = "latest"

      {
        workflow_id: workflow_uuid,
        deadline:    15.minutes.from_now.to_i, # TODO: Put in a config somewhere
        files: {
          input: {
            scripts: "s3://blendergrid-blender-scripts/#{swarm_env}",
            settings: "s3://#{bucket}/projects/#{project.uuid}/jsons",
            project: "s3://#{bucket}/project-sources/#{project.project_source.uuid}"
          },
          output: "s3://#{bucket}/projects/#{project.uuid}/output",
          logs: "s3://#{bucket}/projects/#{project.uuid}/logs"
        },
        executions: [
          {
            job_id:  "sample-frame-$frame",
            command: [
              "$input_dir/project/#{project.main_blend_file}",
              "--python",
              "$input_dir/scripts/init.py",
              "--python",
              "$input_dir/scripts/sample.py",
              "-o",
              "$output_dir/sample-frames/sample-",
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
              "$input_dir/settings/integrity-check.json",
              "--project-dir",
              "$input_dir/project"
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
          project_uuid: project.uuid,
          project_name: project.name,
          user: project.user.email_address
        }
      }
    end
  end
end
