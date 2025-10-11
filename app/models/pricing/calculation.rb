class Pricing::Calculation
  def initialize(benchmark:, node_supplies:, blender_scene:, tweaks: {})
    raise "No Benchmark provided" if benchmark.blank?
    raise "No NodeSupplies provided" if node_supplies.empty?
    raise "No BlenderScene provided" if blender_scene.blank?

    @benchmark = benchmark
    @timing = benchmark.workflow.timing
    @node_supplies = node_supplies.sort_by(&:millicents_per_hour)
    @blender_scene = blender_scene
    @tweaks = tweaks

    @api_time_per_node = 20.seconds
    @boot_time = 5.minutes
    @min_jobs_per_server = 3
    @target_margin = 0.4
    @min_price_cents = 69
  end

  def price_cents
    orig_resolution_x = @blender_scene.scaled_resolution_x
    orig_resolution_y = @blender_scene.scaled_resolution_y
    orig_pixel_count = orig_resolution_x * orig_resolution_y

    sample_resolution_x = @benchmark.scaled_resolution_x
    sample_resolution_y = @benchmark.scaled_resolution_y
    sample_pixel_count = sample_resolution_x * sample_resolution_y

    pixel_factor = orig_pixel_count.fdiv(sample_pixel_count)

    orig_sample_count = @blender_scene.sampling_max_samples * orig_pixel_count
    benchmark_sample_count = @benchmark.sampling_max_samples * sample_pixel_count
    sample_factor = orig_sample_count.fdiv(benchmark_sample_count)

    # Calculate
    job_count = @blender_scene.frames.count # TODO: Take subframes into account
    node_count = Math.sqrt(job_count).ceil # TODO: Take deadline into account
    # max_server_count = [ 1, job_count / @min_jobs_per_server ].max

    # Server cost
    nodes_remaining = node_count
    total_hourly_cost = 0
    @node_supplies.each do |supply|
      nodes_to_use = [ nodes_remaining, supply.capacity ].min
      total_hourly_cost += supply.millicents_per_hour * nodes_to_use
      nodes_remaining -= nodes_to_use
    end
    if nodes_remaining > 0
      total_hourly_cost += @node_supplies.last.millicents_per_hour * nodes_remaining
    end
    avg_node_hour_cost = total_hourly_cost.to_f / node_count / 100_000

    # TODO: Put this into a "timing/timeline" PORO?
    api_time = @api_time_per_node * node_count
    download_time = (@timing["download"]["max"] / 1000).seconds
    server_prep_time = @boot_time + download_time
    frame_init_time = ((@timing["init"]["mean"] +
      @timing["init"]["std"]) / 1000).seconds
    frame_sampling_time = (
      (@timing["sampling"]["mean"] + @timing["sampling"]["std"]) /
      1000).seconds
    frame_sampling_time *= sample_factor
    frame_post_time = ((@timing["post"]["mean"] +
      @timing["post"]["std"]) / 1000).seconds
    frame_post_time *= pixel_factor
    frame_upload_time = (
      (@timing["upload"]["mean"] + @timing["upload"]["std"]) /
      1000).seconds
    frame_upload_time *= pixel_factor

    time_per_frame = frame_init_time + frame_sampling_time + frame_post_time +
      frame_upload_time

    total_frame_time = time_per_frame * job_count

    # Optional: Tiles stitching

    # Optional: Zipping and encoding

    total_time = api_time + server_prep_time + total_frame_time

    # TODO: Does this attriburte belong to the price calculation? Or project? Or render?
    @expected_render_time = total_time

    cost = total_time.in_hours * avg_node_hour_cost

    @min_price_cents + (cost / (1 - @target_margin) * 100).round
  end
end
