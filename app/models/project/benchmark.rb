class Project::Benchmark < ApplicationRecord
  MAX_PIXEL_COUNT = 1280 * 720
  MAX_SPP = 128

  include Workflowable

  belongs_to :project
  before_create :set_sample_settings

  def owner = project

  def make_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    {
      workflow_id: workflow.uuid,
      deadline:    10.minutes.from_now.to_i,
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
            job_id:  "sample-frame-$frame",
            command: [
              "/tmp/project/#{project.blend_filepath}",
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
              sample_settings["resolution_x"].to_s,
              "--resolution-height",
              sample_settings["resolution_y"].to_s,
              "--cycles-samples",
              sample_settings["sampling_max_samples"].to_s,
              "--settings-file",
              "/tmp/settings/integrity-check.json",
              "--project-dir",
              "/tmp/project",
            ],
            parameters: { frame: sample_settings["frame_range"] },
            image: "blendergrid/blender:#{project.blender_version}",
          },
      ],
      metadata: {
        type: "price-calculation",
        created_by: "blendergrid-on-rails",
        project_uuid: project.uuid,
      },
    }
  end

  def handle_completion
    project.finish_benchmarking
  end

  # TODO: Move this to a view helper?
  def price
    return "Calculating..." if price_cents.blank?
    "$#{'%.2f' % (price_cents.fdiv(100))}"
  end

  def resolution_x
    sample_settings["resolution_x"]
  end

  def resolution_y
    sample_settings["resolution_y"]
  end

  def resolution_percentage
    sample_settings["resolution_percentage"]
  end

  def scaled_resolution_x
    (resolution_x * resolution_percentage.fdiv(100)).to_i
  end

  def scaled_resolution_y
    (resolution_y * resolution_percentage.fdiv(100)).to_i
  end

  def sampling_max_samples
    sample_settings["sampling_max_samples"]
  end

  private
    def set_sample_settings
      sample_resolution_x = project.scaled_resolution_x
      sample_resolution_y = project.scaled_resolution_y
      orig_pixel_count = sample_resolution_x * sample_resolution_y
      if orig_pixel_count > MAX_PIXEL_COUNT
        pixel_factor = Math.sqrt(MAX_PIXEL_COUNT.to_f / orig_pixel_count)
        sample_resolution_x = (sample_resolution_x * pixel_factor).round
        sample_resolution_y = (sample_resolution_y * pixel_factor).round
      end

      sample_spp = project.sampling_max_samples
      sample_spp = MAX_SPP if sample_spp > MAX_SPP

      if project.frame_range_type.to_sym == :animation
        frame_start = project.frame_range_start
        frame_end = project.frame_range_end
        frame_step = project.frame_range_step
        all_frames = (frame_start..frame_end).step(frame_step).to_a
      elsif project.frame_range_type.to_sym == :image
        all_frames = [ project.frame_range_single ]
      else
        raise "Unknown frame range type: #{project.frame_range_type}"
      end

      if project.frames.count > 3
        sample_frame_range = [
          project.frames[0],
          project.frames[project.frames.length / 2],
          project.frames[-1],
        ]
      else
        sample_frame_range = all_frames
      end

      self.sample_settings = {
        resolution_x: sample_resolution_x,
        resolution_y: sample_resolution_y,
        resolution_percentage: 100,
        frame_range: sample_frame_range,
        sampling_max_samples: sample_spp,
      }
    end
end
