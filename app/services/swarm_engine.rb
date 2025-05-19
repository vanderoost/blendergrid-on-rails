module SwarmEngine
  TOPIC_PREFIX = "external".freeze
  MAX_SAMPLE_PIXEL_COUNT = 1_000_000
  MAX_SAMPLE_SPP = 48

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

    def publish_render(workflow)
      project = workflow.project
      payload = build_render_payload(project, workflow.uuid)

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

      orig_res_x = project.settings.dig("output", "format", "resolution_x")
      orig_res_y = project.settings.dig("output", "format", "resolution_y")
      orig_spp = project.settings.dig("render", "sampling", "max_samples")
      frame_start = project.settings.dig("output", "frame_range", "start")
      frame_end = project.settings.dig("output", "frame_range", "end")
      frame_step = project.settings.dig("output", "frame_range", "end")

      orig_pixel_count = orig_res_x * orig_res_y
      if orig_pixel_count > MAX_SAMPLE_PIXEL_COUNT
        pixel_factor = Math.sqrt(MAX_SAMPLE_PIXEL_COUNT.to_f / orig_pixel_count.to_f)
        sample_res_x = (orig_res_x * pixel_factor).round
        sample_res_y = (orig_res_y * pixel_factor).round
      else
        sample_res_x = orig_res_x
        sample_res_y = orig_res_y
      end

      all_frames = (frame_start..frame_end).step(frame_step).to_a
      if all_frames.length > 3
        sample_frames = [
          all_frames[0],
          all_frames[all_frames.length / 2],
          all_frames[-1]
        ]
      else
        sample_frames = all_frames
      end

      sample_spp = [ MAX_SAMPLE_SPP, orig_spp ].min
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
          user: project.user.email
        }
      }
    end

    def build_render_payload(project, workflow_uuid)
      bucket      = Rails.application.credentials.dig(:swarm_engine, :bucket)
      swarm_env   = Rails.application.credentials.dig(:swarm_engine, :env)

      frame_start = project.settings.dig("output", "frame_range", "start")
      frame_end = project.settings.dig("output", "frame_range", "end")
      frame_step = project.settings.dig("output", "frame_range", "end")

      blender_version = "latest"

      {
        workflow_id: workflow_uuid,
        deadline:    5.hours.from_now.to_i, # TODO: Put in a config somewhere
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
            job_id:  "frame-$frame",
            command: [
              "$input_dir/project/#{project.main_blend_file}",
              "--python",
              "$input_dir/scripts/init.py",
              "-o",
              "$output_dir/frames/frame-", # TODO: Use the project output file name
              "-f",
              "$frame",
              "--",
              "--settings-file",
              "$input_dir/settings/integrity-check.json",
              "--project-dir",
              "$input_dir/project"
            ],
            parameters: {
              frame: { start: frame_start, end: frame_end, step: frame_step }
            },
            image: "blendergrid/blender:#{blender_version}"
          }
        ],
        metadata: {
          type: "render",
          created_by: "blendergrid-on-rails",
          project_uuid: project.uuid,
          project_name: project.name,
          user: project.user.email
        }
      }
    end
  end
end
