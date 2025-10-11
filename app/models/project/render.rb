class Project::Render < ApplicationRecord
  include Workflowable

  belongs_to :project

  before_destroy :cancel_project

  def owner = project

  def make_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?
    expected_render_time = 1800 # TODO: Figure out where to calculate and store this
    # expected_render_time = project.benchmarks.last.expected_render_time
    # if expected_render_time.nil?
    #   raise "The price calculation's expected_render_time is nil"
    # end

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    # Settings
    if project.frame_range_type == "animation"
      frame_params = {
        start: project.frame_range_start,
        end: project.frame_range_end,
        step: project.frame_range_step,
      }
    elsif project.frame_range_type == "image"
      frame_params = project.frame_range_single
    else
      raise "Unknown frame range type: #{project.frame_range_type}"
    end

    # TODO: Put the Blender version in the settings as well (from the Swarm Engine)
    blender_version = "latest"

    {
      workflow_id: workflow.uuid,
      deadline: expected_render_time.seconds.from_now.to_i,
      files: {
        input: {
          scripts: "s3://blendergrid-blender-scripts/#{swarm_engine_env}",
          settings: "s3://#{bucket}/projects/#{project.uuid}/jsons",
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}",
        },
        logs: "s3://#{bucket}/projects/#{project.uuid}/logs",
        output: "s3://#{bucket}/projects/#{project.uuid}/output",
      },
      executions: [
        {
          job_id: "frame-$frame",
          command: [
            "--enable-autoexec",
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
            "/tmp/project",
            "--cycles-samples",
            project.sampling_max_samples.to_s,
          ],
          parameters: { frame: frame_params },
          image: "blendergrid/blender:#{blender_version}",
        },
      ],
      metadata: {
        type: "render",
        created_by: "blendergrid-on-rails",
        project_uuid: project.uuid,
        project_name: project.blend_filepath,
      },
    }
  end

  def handle_completion
    project.finish_rendering if workflow.finished?
    project.fail if workflow.failed?
  end

  private
    def cancel_project
      project.cancel
    end
end
