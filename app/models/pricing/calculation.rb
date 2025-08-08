class Pricing::Calculation < ApplicationRecord
  def initialize(project:)
    @settings = project.settings
    @benchmark = project.benchmark

    @api_time_per_node = 20.seconds
    @boot_time = 5.minutes
    @min_jobs_per_server = 3
    @target_margin = 0.4
    @min_price_cents = 69
  end

  def calculate_price
    # Scene specific
    orig_pixel_count = @settings.res_x * @settings.res_y
    sample_pixel_count = @benchmark.sample_settings.res_x *
      @benchmark.sample_settings.res_y
    pixel_factor = orig_pixel_count.to_f / sample_pixel_count
    logger.info "Pixel factor: #{pixel_factor}"

    orig_sample_count = @settings.spp * orig_pixel_count
    sample_sample_count = @benchmark.sample_settings.spp * sample_pixel_count
    sample_factor = orig_sample_count.to_f / sample_sample_count
    logger.info "SPP factor: #{sample_factor}"

    # Calculate
    job_count = @settings.frame_count # TODO: Take subframes into account
    node_count = Math.sqrt(job_count).ceil
    # max_server_count = [ 1, job_count / @min_jobs_per_server ].max

    # Server cost
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
      total_hourly_cost += @node_supplies.last.millicents_per_hour * nodes_remaining
    end
    avg_node_hour_cost = total_hourly_cost.to_f / node_count / 100_000
    logger.info "Total hourly cost: #{total_hourly_cost}"
    logger.info "Average hourly cost: #{avg_node_hour_cost}"

    # TODO: Put this into a "timing/timeline" PORO?
    api_time = @api_time_per_node * node_count
    download_time = (timing["download"]["max"] / 1000).seconds
    server_prep_time = @boot_time + download_time
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

    # TODO: Does this attriburte belong to the price calculation? Or project? Or render?
    @expected_render_time = total_time

    cost = total_time.in_hours * avg_node_hour_cost

    @price_cents = @min_price_cents + (cost / (1 - @target_margin) * 100).round
  end
end
