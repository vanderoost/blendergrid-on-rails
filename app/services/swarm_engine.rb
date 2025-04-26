module SwarmEngine
  TOPIC_PREFIX = "external".freeze

  class << self
    def publish_integrity_check(workflow)
      project = workflow.project
      payload = build_integrity_payload(project, workflow.uuid)

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

    def build_integrity_payload(project, workflow_uuid)
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
            image: {
              command: [ "python",
                        "$input_dir/scripts/get_blender_image.py",
                        "$input_dir/project/#{project.main_blend_file}" ]
            }
          }
        ],
        metadata: { type: "integrity-check", created_by: "blendergrid-on-rails" }
      }
    end
  end
end
