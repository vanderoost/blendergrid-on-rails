class Project::Render < ApplicationRecord
  include Workflowable

  belongs_to :project

  before_destroy :cancel_project

  def owner = project

  def make_start_message
    swarm_engine_env = Rails.configuration.swarm_engine[:env]

    {
      workflow_id: workflow.uuid,
      deadline: workflow.project.tweaks_deadline_hours.hours.from_now.to_i,
      files: {
        input: { scripts: "s3://blendergrid-blender-scripts/#{swarm_engine_env}" },
        logs: "#{s3_project_path}/logs",
      },
      executions: executions,
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
    def executions
      render_ex_id = SecureRandom.uuid
      result = [ render_execution(render_ex_id) ]

      if project.frames.count > 1
        result << zip_execution(render_ex_id)

        if project.file_output_file_format == "FFMPEG"
          result << video_encoding(render_ex_id)
        end
      end

      result
    end

    def render_execution(render_ex_id)
      {
        execution_id: render_ex_id,
        job_id: "frame-$frame",
        files: render_files,
        command: [
          "--enable-autoexec",
          "/tmp/project/#{project.blend_filepath}",
          "--scene",
          project.current_blender_scene.name,
          "--python",
          "/tmp/scripts/init.py",
          "-o",
          "/tmp/frames/frame-", # TODO: Use the project output file name
          "-f",
          "$frame",
          "--",
          "--settings-file",
          "/tmp/settings/settings.json",
          "--project-dir",
          "/tmp/project",
          "--cycles-samples",
          project.sampling_max_samples.to_s,
        ],
        parameters: { frame: frame_params },
        image: "blendergrid/blender:#{project.blender_version}",
      }
    end

    def zip_execution(render_ex_id)
      {
        job_id: "compress-frames",
        files: zip_files,
        command: [
          "python3",
          "/tmp/scripts/compress-chunks.py",
          "/tmp/frames",
          "/tmp/zip/#{project.name}-frames",
        ],
        dependencies: [ render_ex_id ],
        image: "blendergrid/tools",
      }
    end

    def video_encoding
      {}
    end

    def render_files
      key_prefix = Rails.configuration.swarm_engine[:key_prefix]
      {
        input: {
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}",
          settings: "#{s3_project_path}/jsons",
        },
        output: { frames: "#{s3_project_path}/frames" },
      }
    end

    def zip_files
      {
        input: { frames: "#{s3_project_path}/frames" },
        output: { zip: "#{s3_project_path}/output" },
      }
    end

    def video_encoding_files
    end

    def s3_project_path
      "s3://#{bucket}/projects/#{project.uuid}"
    end

    def bucket
      @bucket ||= Rails.configuration.swarm_engine[:bucket]
    end

    def frame_params
      if project.frame_range_type == "animation"
        {
          start: project.frame_range_start,
          end: project.frame_range_end,
          step: project.frame_range_step,
        }
      elsif project.frame_range_type == "image"
        project.frame_range_single
      else
        raise "Unknown frame range type: #{project.frame_range_type}"
      end
    end

    def cancel_project
      project.cancel
    end
end
