class Project::Benchmark < ApplicationRecord
  include Workflowable
  MAX_PIXEL_COUNT = 1280 * 720
  MAX_SPP = 128


  belongs_to :project
  attr_accessor :settings
  delegate :settings, to: :project


  def owner = project

  def make_workflow_start_message
    # TODO: Should this be the concern of this model? Or let some outside control
    # (SwarmEngine) handle this kind of logic?

    swarm_engine_env = Rails.configuration.swarm_engine[:env]
    bucket = Rails.configuration.swarm_engine[:bucket]
    key_prefix = Rails.configuration.swarm_engine[:key_prefix]

    # Resolution
    benchmark_res_x = project.settings.res_x
    benchmark_res_y = project.settings.res_y
    orig_pixel_count = benchmark_res_x * benchmark_res_y
    if orig_pixel_count > MAX_PIXEL_COUNT
      pixel_factor = Math.sqrt(MAX_PIXEL_COUNT.to_f / orig_pixel_count)
      benchmark_res_x = (benchmark_res_x * pixel_factor).round
      benchmark_res_y = (benchmark_res_y * pixel_factor).round
      logger.info "Custom resolution: #{benchmark_res_x}x#{benchmark_res_y}"
    end

    # Sample count
    benchmark_spp = project.settings.spp
    if benchmark_spp > MAX_SPP
      benchmark_spp = MAX_SPP
      logger.info "Custom SPP: #{benchmark_spp}"
    end

    # Frames
    if project.settings.frame_range_type == :animation
      frame_start = project.settings.output.frame_range.start
      frame_end = project.settings.output.frame_range.end
      frame_step = project.settings.output.frame_range.step
      all_frames = (frame_start..frame_end).step(frame_step).to_a
    elsif project.settings.frame_range_type == :image
      all_frames = [ project.settings.output.frame_range.single ]
    end

    if project.settings.frame_count > 3
      sample_frames = [
        all_frames[0],
        all_frames[all_frames.length / 2],
        all_frames[-1],
      ]
    else
      sample_frames = all_frames
    end

    # TODO: This side effect doesn't really belong here.
    update(sample_settings: {
      output: {
        format: {
          resolution_x: benchmark_res_x,
          resolution_y: benchmark_res_y,
          resolution_percentage: 100,
        },
        frame_range: sample_frames,
      },
      render: {
        sampling: { max_samples: benchmark_spp },
      },
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
          project: "s3://#{bucket}/#{key_prefix}/#{project.upload.uuid}",
        },
        logs: "s3://#{bucket}/projects/#{project.uuid}/logs",
        output: "s3://#{bucket}/projects/#{project.uuid}/output",
      },
      executions: [
          {
            job_id:  "sample-frame-$frame",
            command: [
              "/tmp/project/#{project.blend_file}",
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
              benchmark_res_x.to_s,
              "--resolution-height",
              benchmark_res_y.to_s,
              "--cycles-samples",
              benchmark_spp.to_s,
              "--settings-file",
              "/tmp/settings/integrity-check.json",
              "--project-dir",
              "/tmp/project",
            ],
            parameters: { frame: sample_frames },
            image: "blendergrid/blender:#{blender_version}",
          },
      ],
      metadata: {
        type: "price-calculation",
        created_by: "blendergrid-on-rails",
        project_uuid: project.uuid,
      },
    }
  end

  def handle_result(result)
    logger.info "Benchmark#handle_result(#{result}"
    update(
      node_provider_id: result.dig(:node_provider_id),
      node_type_name: result.dig(:node_type_name),
      timing: result.dig(:timing),
    )

    # TODO: This should be kicked off somewhere else (state machine?)
    calculate_price

    ProjectMailer.project_benchmark_finished(project).deliver_later
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
    api_time_per_node = 20.seconds
    boot_time = 5.minutes
    min_jobs_per_server = 3
    target_margin = 0.7
    min_price_cents = 69

    # Calculate
    job_count = project.settings.frame_count # TODO: Take subframes into account
    node_count = Math.sqrt(job_count).ceil
    # max_server_count = [ 1, job_count / min_jobs_per_server ].max

    # Server cost
    # TODO: Move this somewhere else - Unit test it
    nodes_remaining = node_count
    total_hourly_cost = 0
    supplies = NodeSupply
      .where(provider_id: node_provider_id, type_name: node_type_name)
      .order(:millicents_per_hour)
    if supplies.empty?
      raise "No supplies found for #{node_provider_id}:#{node_type_name}"
    end
    supplies.each do |supply|
      nodes_to_use = [ nodes_remaining, supply.capacity ].min
      total_hourly_cost += supply.millicents_per_hour * nodes_to_use
      nodes_remaining -= nodes_to_use
    end
    if nodes_remaining > 0
      total_hourly_cost += supplies.last.millicents_per_hour * nodes_remaining
    end
    avg_node_hour_cost = total_hourly_cost.to_f / node_count / 100_000
    logger.info "Total hourly cost: #{total_hourly_cost}"
    logger.info "Average hourly cost: #{avg_node_hour_cost}"

    # TODO: Put this into a "timing/timeline" PORO?
    api_time = api_time_per_node * node_count
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

    time_per_frame = frame_init_time + frame_sampling_time + frame_post_time +
      frame_upload_time

    total_frame_time = time_per_frame * job_count

    # Optional: Tiles stitching

    # Optional: Zipping and encoding

    total_time = api_time + server_prep_time + total_frame_time
    logger.info "Total time: #{total_time}"

    # TODO: Does this attriburte belong to the price calculation? Or project? Or render?
    self.expected_render_time = total_time

    cost = total_time.in_hours * avg_node_hour_cost

    self.price_cents = min_price_cents + (cost / (1 - target_margin) * 100).round
    self.save
  end

  # TODO: Move this to a view helper?
  def price
    return "Calculating..." if price_cents.blank?
    "$#{'%.2f' % (price_cents / 100.0)}"
  end

  private
    def start_workflow
      project.start_benchmarking
      project.settings_revisions.create(settings: create_settings)
      create_workflow
    end

    def create_settings
      { output: { frame_range: { type: @settings[:frame_range_type] } } }
    end
end
