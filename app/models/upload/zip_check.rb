class Upload::ZipCheck < ActiveRecord::Base
  include Workflowable

  belongs_to :upload

  def owner
    upload
  end

  def make_start_message
    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    {
      workflow_id: workflow.uuid,
      deadline:    Time.current.to_i,
      files: {
        input: {
          upload: "s3://#{bucket}/#{key_prefix}/#{upload.uuid}",
          scripts: "s3://blendergrid-blender-scripts/#{swarm_engine_env}",
        },
        output: "s3://#{bucket}/projects/#{upload.uuid}/jsons",
        logs: "s3://#{bucket}/projects/#{upload.uuid}/logs",
      },
      executions: [
        {
          job_id: "zip-check",
          command: [
            "python3",
            "/tmp/scripts/zip_check.py",
            "/tmp/upload/#{zip_filename}",
            "--output",
            "/tmp/output/zip_contents.json",
          ],
          image: "blendergrid/tools",
        },
      ],
      metadata: {
        type: "zip-check",
        zip_filename: zip_filename,
        created_by: "blendergrid-on-rails",
      },
    }
  end

  def handle_completion
    contents = workflow.result&.dig("zip_contents") || fetch_contents_from_s3
    update(zip_contents: contents)
    upload.zip_check_done(self)
  end

  private
    def fetch_contents_from_s3
      key = "projects/#{upload.uuid}/jsons/zip_contents.json"
      JSON.parse(bucket.object(key).get.body.read)
    rescue Aws::S3::Errors::NoSuchKey, JSON::ParserError => e
      Rails.logger.warn(
        "Zip check S3 fallback failed for upload #{upload.uuid}: #{e.message}"
      )
      nil
    end

    def bucket
      Aws::S3::Resource.new.bucket(Rails.configuration.swarm_engine[:bucket])
    end
end
