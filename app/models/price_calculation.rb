class PriceCalculation < ApplicationRecord
  MAX_PIXEL_COUNT = 1280 * 720
  MAX_SPP = 128

  include Workflowable

  belongs_to :project

  def make_workflow_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    # Resolution
    sample_res_x = project.settings.res_x
    sample_res_y = project.settings.res_y
    orig_pixel_count = sample_res_x * sample_res_y
    if orig_pixel_count > MAX_PIXEL_COUNT
      pixel_factor = Math.sqrt(MAX_PIXEL_COUNT.to_f / orig_pixel_count)
      sample_res_x = (sample_res_x * pixel_factor).round
      sample_res_y = (sample_res_y * pixel_factor).round
      logger.info "Custom resolution: #{sample_res_x}x#{sample_res_y}"
    end

    # Sample count
    sample_spp = project.settings.spp
    if sample_spp > MAX_SPP
      sample_spp = MAX_SPP
      logger.info "Custom SPP: #{sample_spp}"
    end

    # Frames
    frame_start = project.settings.output.frame_range.start
    frame_end = project.settings.output.frame_range.end
    frame_step = project.settings.output.frame_range.step
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

    # TODO: This side effect doesn't really belong here.
    update(sample_settings: {
      output: {
        format: {
          resolution_x: sample_res_x,
          resolution_y: sample_res_y,
          resolution_percentage: 100
        },
        frame_range: sample_frames
      },
      render: {
        sampling: {
          max_samples: sample_spp
        }
      }
    })

    # TODO: Put the Blender version in the settings as well (from the Swarm Engine)
    blender_version = "latest"

    {
      workflow_id: workflow.uuid,
      deadline:    10.minutes.from_now.to_i,
      files: {
        input: {
          scripts: "s3://blendergrid-blender-scripts/#{swarm_engine_env}",
          settings: "s3://#{bucket}/projects/#{project.uuid}/jsons",
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}"
        },
      output: "s3://#{bucket}/projects/#{project.uuid}/output",
      logs: "s3://#{bucket}/projects/#{project.uuid}/logs"
      },
      executions: [
          {
            job_id:  "sample-frame-$frame",
            command: [
              "/tmp/project/#{project.main_blend_file}",
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
              sample_res_x.to_s,
              "--resolution-height",
              sample_res_y.to_s,
              "--cycles-samples",
              sample_spp.to_s,
              "--settings-file",
              "/tmp/settings/integrity-check.json",
              "--project-dir",
              "/tmp/project"
            ],
            parameters: { frame: sample_frames },
            image: "blendergrid/blender:#{blender_version}"
          }
      ],
      metadata: {
        type: "price-calculation",
        created_by: "blendergrid-on-rails",
        project_uuid: project.uuid
      }
    }
  end

  def handle_result(result)
    update(node_type: result.dig("node_type"), timing: result.dig("timing"))

    # This should be kicked off somewhere else, maybe in the state machine?
    calculate_price
  end

  def calculate_price
    # Scene specific
    orig_pixel_count = project.settings.res_x * project.settings.res_y
    sample_pixel_count = project.sample_settings.res_x * project.sample_settings.res_y
    pixel_factor = orig_pixel_count.to_f / sample_pixel_count
    logger.info "Pixel factor: #{pixel_factor}"

    orig_sample_count = project.settings.spp * orig_pixel_count
    sample_sample_count = project.sample_settings.spp * sample_pixel_count
    sample_factor = orig_sample_count.to_f / sample_sample_count
    logger.info "SPP factor: #{sample_factor}"

    # Variables
    api_time_per_server = 20.seconds
    boot_time = 5.minutes
    min_jobs_per_server = 3
    server_hour_price = 0.50
    target_margin = 0.7
    min_price_cents = 69

    # Calculate
    job_count = project.settings.frame_count # TODO: Take subframes into account
    server_count = Math.sqrt(job_count).ceil
    max_server_count = [ 1, job_count / min_jobs_per_server ].max

    # TODO: Put this into a "timing/timeline" PORO?
    api_time = api_time_per_server * server_count
    download_time = (timing["download"]["max"] / 1000).seconds
    server_prep_time = boot_time + download_time
    frame_init_time = ((timing["init"]["mean"] + timing["init"]["std"]) / 1000).seconds
    frame_sampling_time = (
      (timing["sampling"]["mean"] + timing["sampling"]["std"]) / 1000).seconds
    frame_sampling_time *= sample_factor
    frame_post_time = ((timing["post"]["mean"] + timing["post"]["std"]) / 1000).seconds
    frame_post_time *= pixel_factor
    frame_upload_time = (
      (timing["upload"]["mean"] + timing["upload"]["std"]) / 1000).seconds
    frame_upload_time *= pixel_factor

    time_per_frame = frame_init_time + frame_sampling_time + frame_post_time
      + frame_upload_time

    total_frame_time = time_per_frame * job_count

    # Optional: Tiles stitching

    # Optional: Zipping and encoding

    total_time = api_time + server_prep_time + total_frame_time
    logger.info "Total time: #{total_time}"
    cost = total_time.in_hours * server_hour_price

    self.price_cents = min_price_cents + (cost / (1 - target_margin) * 100).round
    self.save
  end

  def price
    return "Calculating..." if price_cents.blank?
    price_cents / 100.0
  end
end
