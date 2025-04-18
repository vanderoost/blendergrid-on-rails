require "aws-sdk-sns"

class SwarmEngineService
  def initialize
    @swarm_env = Rails.application.credentials.swarm_engine.env
    @bucket = Rails.application.credentials.swarm_engine.bucket

    client_args = {
      region: "us-east-1",
      credentials: Aws::Credentials.new(
        Rails.application.credentials.aws.access_key_id,
        Rails.application.credentials.aws.secret_access_key,
      )
    }

    if Rails.application.credentials.aws.endpoint
      Rails.logger.info("Using custom endpoint for SNS: #{Rails.application.credentials.aws.endpoint}")
      client_args[:endpoint] = Rails.application.credentials.aws.endpoint
    else
      Rails.logger.info("Using default endpoint for SNS")
    end

    @client = Aws::SNS::Client.new(**client_args)
  end

  def start_integrity_check_workflow(workflow)
    project = workflow.project
    Rails.logger.info "Starting Integrity Check for Project(#{project.name})"

    workflow.uuid = SecureRandom.uuid

    message = {
      workflow_id: workflow.uuid,
      deadline: Time.now.to_i,
      files: {
        input: {
          scripts: "s3://blendergrid-blender-scripts/#{@swarm_env}",
          project: "s3://#{@bucket}/project-sources/#{project.project_source.uuid}"
        },
        output: "s3://#{@bucket}/projects/#{project.uuid}/jsons",
        logs: "s3://#{@bucket}/projects/#{project.uuid}/logs"
      },
      executions: [
        {
          job_id: "integrity-check",
          command: [
            "$input_dir/project/#{project.main_blend_file}",
              "--python",
              "$input_dir/scripts/old_integrity_check.py",
              "--",
              "$output_dir"
          ],
          image: {
            command: [
              "python",
              "$input_dir/scripts/get_blender_image.py",
              "$input_dir/project/#{project.main_blend_file}"
            ]
          }
        }
      ],
      metadata: { type: "integrity-check", created_by: "blendergrid-on-rails" }
    }

    self.publish_event(message)
  end

  def publish_event(message)
    event_topic = "external"

    aws_account_id = Rails.application.credentials.aws.account_id
    topic_arn = "arn:aws:sns:us-east-1:#{aws_account_id}:#{event_topic}-#{@swarm_env}-topic"

    Rails.logger.info("Publishing event to #{topic_arn}")

    @client.publish(
      topic_arn:,
      message: message.to_json,
      message_attributes: {
        event_type: { data_type: "String", string_value: "workflow_started" }
      }
    )
  end
end
