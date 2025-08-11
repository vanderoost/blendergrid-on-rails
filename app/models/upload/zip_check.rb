class Upload::ZipCheck < ActiveRecord::Base
  include Workflowable

  belongs_to :upload

  def owner = upload

  def make_workflow_start_message
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
                    "/tmp/upload/#{zip_file}",
                    "--output",
                    "/tmp/output/zip_contents.json",
          ],
          image: "blendergrid/tools",
        },
      ],
      metadata: { type: "zip-check", created_by: "blendergrid-on-rails" },
    }
  end

  def handle_result(result)
    # result = {"zip_contents" => ["subfolder/", "subfolder/cube.blend", "subfolder/sub-sub-folder/", "subfolder/sub-sub-folder/veve.blend"], "timing" => #<ActionController::Parameters {"download" => {"min" => 1949, "max" => 1949, "mean" => 1949, "std" => 0}, "unpack" => {"min" => 18, "max" => 18, "mean" => 18, "std" => 0}, "execute" => {"min" => 263, "max" => 263, "mean" => 263, "std" => 0}, "process_docker_log" => {"min" => 1, "max" => 1, "mean" => 1, "std" => 0}, "upload" => {"min" => 1944, "max" => 1944, "mean" => 1944, "std" => 0}} permitted: false>}
    update(zip_contents: result.dig("zip_contents"))
    upload.zip_check_done(self)
  end

  private
    def start_workflow
      create_workflow
    end
end
