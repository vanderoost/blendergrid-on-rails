require "aws-sdk-s3"

class Render < ApplicationRecord
  include Workflowable

  def make_workflow_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?
    expected_render_time = project.quotes.last.expected_render_time
    if expected_render_time.nil?
      raise "The price calculation's expected_render_time is nil"
    end

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    # Settings
    frame_start = project.settings.output.frame_range.start
    frame_end = project.settings.output.frame_range.end
    frame_step = project.settings.output.frame_range.step

    # TODO: Put the Blender version in the settings as well (from the Swarm Engine)
    blender_version = "latest"

    {
      workflow_id: workflow.uuid,
      deadline: expected_render_time.seconds.from_now.to_i,
      files: {
        input: {
          scripts: "s3://blendergrid-blender-scripts/#{swarm_engine_env}",
          settings: "s3://#{bucket}/projects/#{project.uuid}/jsons",
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}"
        },
        logs: "s3://#{bucket}/projects/#{project.uuid}/logs",
        output: "s3://#{bucket}/projects/#{project.uuid}/output"
      },
      executions: [
        {
          job_id: "frame-$frame",
          command: [
            "/tmp/project/#{project.blend_filepath}",
            "--python",
            "/tmp/scripts/init.py",
            "-o",
            "/tmp/output/frames/frame-", # TODO: Use the project output file name
            "-f",
            "$frame",
            "--",
            "--settings-file",
            "/tmp/settings/integrity-check.json",
            "--project-dir",
            "/tmp/project"
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
        project_name: project.blend_filepath
      }
    }
  end

  def frame_urls
    bucket_name = Rails.configuration.swarm_engine[:bucket]
    prefix = "projects/#{project.uuid}/output/frames/"
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(bucket_name)
    bucket.objects(prefix: prefix)
      .sort_by(&:key)
      .map { |obj| obj.presigned_url(:get, expires_in: 1.hour.in_seconds) }
  end

  def handle_result(result)
    logger.info "Render result: #{result}"
    ProjectMailer.project_render_finished(project).deliver_later
  end

  private
    def start_workflow
      project.start_rendering
      create_workflow
    end
end
