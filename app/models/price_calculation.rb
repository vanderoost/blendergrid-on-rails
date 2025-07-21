class PriceCalculation < ApplicationRecord
  include Workflowable

  belongs_to :project

  def make_workflow_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    # TODO: Use real data
    sample_res_x = 960
    sample_res_y = 540
    sample_spp = 64
    sample_frames = [ 1, 5, 10 ]
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
            parameters: {
                frame: sample_frames
            },
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
    self.node_type = result.dig("node_type")
    self.timing = result.dig("timing")
    calculate_price
    save!
  end

  def calculate_price
    server_count = 1

    # Scene specific
    sample_factor = 5.0
    pixel_factor = 2.0

    # Variables
    api_time_per_server = 20.seconds
    boot_time = 5.minutes
    min_jobs_per_server = 3
    server_hour_price = 0.50
    target_margin = 0.7

    # Calculate
    job_count = 100 # TODO: Actually calculate this
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

    self.price_cents = (cost / (1 - target_margin) * 100).ceil
    self.save
  end

  def price
    return "Calculating..." if price_cents.blank?
    price_cents / 100.0
  end
end
