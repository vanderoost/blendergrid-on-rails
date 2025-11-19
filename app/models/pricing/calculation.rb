class Pricing::Calculation
  DEBUG = false
  MIN_NODES_PER_ZONE = 4
  MAX_NODE_COUNT = 75 # Maybe depend on node_supplies?

  def initialize(benchmark:, node_supplies:, blender_scene:, tweaks: {})
    raise "No Benchmark provided" if benchmark.blank?
    raise "No NodeSupplies provided" if node_supplies.empty?
    raise "No BlenderScene provided" if blender_scene.blank?

    @benchmark = benchmark
    @timing = benchmark.workflow.timing
    @node_supplies = node_supplies.sort_by(&:millicents_per_hour)
    @blender_scene = blender_scene
    @tweaks = tweaks

    # Configuration
    @api_time_per_node = 20.seconds
    @max_node_count = MAX_NODE_COUNT
    @node_boot_time = 5.minutes
    @min_jobs_per_node = 3
    @min_deadline_factor = 1.5
    @max_deadline_factor = 3.0
    @deadline_hours_min = 2
    @min_price_cents = Rails.application.credentials[:pricing][:min_price_cents]
    @margin_slow = Rails.application.credentials[:pricing][:margin_slow]
    @margin_fast = Rails.application.credentials[:pricing][:margin_fast]

    calculate
  end


  def price_cents
    @price_cents
  end

  def deadline_hours_min
    @deadline_hours_min
  end

  def deadline_hours_max
    @deadline_hours_max
  end

  private
    def calculate
      # GENERAL
      download_time = @timing.dig("download", "max").milliseconds
      unzip_time = (@timing.dig("unzip", "max") || 0).milliseconds

      # GENERAL JOB TIMES
      init_time = @timing.dig("init", "mean").milliseconds +
        @timing.dig("init", "std").milliseconds
      sampling_time = @timing.dig("sampling", "mean").milliseconds +
        @timing.dig("sampling", "std").milliseconds
      sampling_time *= sample_factor
      post_time = @timing.dig("post", "mean").milliseconds +
        @timing.dig("post", "std").milliseconds
      post_time *= pixel_factor
      upload_time = @timing.dig("upload", "max").milliseconds

      # GENERAL POST RENDERING
      zip_time = (
        @blender_scene.frames.count * orig_pixel_count
      ).fdiv(10_000_000).seconds
      encode_time = (
        @blender_scene.frames.count * orig_pixel_count
      ).fdiv(10_000_000).seconds

      # MAX NODES - MIN DEADLINE
      max_node_count = [
        @max_node_count,
        @blender_scene.frames.count / @min_jobs_per_node,
      ].min
      max_node_count = [ max_node_count, 1 ].max
      puts "MAX NODE COUNT: #{max_node_count}" if DEBUG

      api_time = @api_time_per_node * max_node_count

      min_wall_time = api_time + @node_boot_time + download_time + unzip_time +
        (init_time + sampling_time + post_time + upload_time) *
        (@blender_scene.frames.count / max_node_count) +
        [ zip_time, encode_time ].max
      safe_min_wall_time = min_wall_time * @min_deadline_factor

      @deadline_hours_min = [ @deadline_hours_min,
        safe_min_wall_time.in_hours.ceil ].max
      puts "MIN DEADLINE: #{@deadline_hours_min}h" if DEBUG

      # ONE NODE - MAX DEADLINE
      api_time = @api_time_per_node

      job_time = init_time + sampling_time + post_time + upload_time
      all_jobs_time = job_time * @blender_scene.frames.count

      max_wall_time = api_time + @node_boot_time + download_time + unzip_time +
        all_jobs_time + [ zip_time, encode_time ].max
      puts "MAX WALL TIME (ONE NODE): #{max_wall_time.round}" if DEBUG
      allowed_max_deadline = max_wall_time * @max_deadline_factor

      @deadline_hours_max = [
        @deadline_hours_min + 1,
        allowed_max_deadline.in_hours.ceil,
      ].max
      puts "MAX DEADLINE: #{@deadline_hours_max}h" if DEBUG

      # ACTUAL PREFERRED DEADLINE
      deadline_hours = [ @deadline_hours_max, @tweaks["deadline_hours"] ].min
      deadline_hours = [ @deadline_hours_min, deadline_hours ].max
      puts "ACTUAL PREFERRED DEADLINE: #{deadline_hours}h" if DEBUG

      # Figure out how many nodes we need
      deadline = deadline_hours.hours
      a = @api_time_per_node.in_seconds
      j = all_jobs_time.in_seconds
      d = deadline.in_seconds
      b = @node_boot_time.in_seconds
      sqrt_term = (d - b)**2 - 4*a*j
      puts "SQRT TERM: #{sqrt_term}" if DEBUG
      if sqrt_term.positive?
        node_count = (d - b - Math.sqrt(sqrt_term)) / (2*a)
        puts "NODE COUNT FORMULA: #{node_count.round 4}" if DEBUG
      else
        node_count = j / (d - b)
        puts "FALL BACK TO SIMPLE FORMULA: #{node_count.round 4}" if DEBUG
      end
      puts "NODE COUNT: #{node_count}" if DEBUG
      node_count = [ 1, [ node_count.ceil, max_node_count ].min ].max

      # What do the nodes cost?
      nodes_remaining = node_count
      total_hourly_cost = 0
      @node_supplies.each do |supply|
        capacity = [ supply.capacity, MIN_NODES_PER_ZONE ].max
        nodes_to_use = [ nodes_remaining, capacity ].min
        total_hourly_cost += supply.millicents_per_hour * nodes_to_use
        nodes_remaining -= nodes_to_use
        break if nodes_remaining < 1
      end
      if nodes_remaining > 0
        total_hourly_cost += @node_supplies.last.millicents_per_hour * nodes_remaining
      end
      avg_node_hour_cost = total_hourly_cost.to_f / node_count / 1_000
      puts "AVG NODE HOUR COST: #{avg_node_hour_cost.round 4} cents" if DEBUG

      # How long do we expect to run the nodes?
      node_time = (@api_time_per_node + @node_boot_time + download_time + unzip_time) *
        node_count + all_jobs_time + [ zip_time, encode_time ].max
      puts "NODE TIME: #{node_time.round 4}s" if DEBUG

      node_cost = node_time.in_hours * avg_node_hour_cost
      puts "NODE COST: #{node_cost.round 4} cents" if DEBUG

      speed_fac = 1.0 - (deadline_hours - @deadline_hours_min).fdiv(
        @deadline_hours_max - @deadline_hours_min)
      speed_fac = speed_fac ** 1.5
      puts "SPEED FAC: #{speed_fac.round 4}" if DEBUG

      margin = speed_fac * @margin_fast + (1 - speed_fac) * @margin_slow
      puts "MARGIN: #{margin.round 4}" if DEBUG

      @price_cents = @min_price_cents + (node_cost * margin).ceil
      puts "PRICE: #{@price_cents} cents" if DEBUG
    end

    def pixel_factor
      return @pixel_factor if defined? @pixel_factor

      @pixel_factor = orig_pixel_count.fdiv(benchmark_pixel_count)
    end

    def sample_factor
      return @sample_factor if defined? @sample_factor

      @sample_factor = orig_sample_count.fdiv(benchmark_sample_count)
    end

    def orig_pixel_count
      return @orig_pixel_count if defined? @orig_pixel_count

      orig_resolution_x = @blender_scene.scaled_resolution_x(
        @tweaks["resolution_percentage"]
      )
      orig_resolution_y = @blender_scene.scaled_resolution_y(
        @tweaks["resolution_percentage"]
      )

      @orig_pixel_count = orig_resolution_x * orig_resolution_y
    end

    def benchmark_pixel_count
      return @benchmark_pixel_count if defined? @benchmark_pixel_count

      sample_resolution_x = @benchmark.scaled_resolution_x
      sample_resolution_y = @benchmark.scaled_resolution_y

      @benchmark_pixel_count = sample_resolution_x * sample_resolution_y
    end

    def orig_sample_count
      return @orig_sample_count if defined? @orig_sample_count

      max_samples = @tweaks["sampling_max_samples"] ||
        @blender_scene.sampling_max_samples

      @orig_sample_count = max_samples * orig_pixel_count
    end

    def benchmark_sample_count
      return @benchmark_sample_count if defined? @benchmark_sample_count

      @benchmark_sample_count = @benchmark.sampling_max_samples * benchmark_pixel_count
    end
end
