class Pricing::Calculation
  MIN_NODES_PER_ZONE = 4
  MAX_NODE_COUNT = 75 # Maybe depend on node_supplies?

  attr_reader :price_cents, :deadline_hours_min, :deadline_hours_max

  def initialize(benchmark:, node_supplies:, blender_scene:, tweaks: {})
    raise "No NodeSupplies provided" if node_supplies.empty?

    # JobEstimate validates the benchmark and blender_scene
    @estimate = Pricing::JobEstimate.new(
      benchmark: benchmark,
      blender_scene: blender_scene,
      tweaks: tweaks,
    )
    @node_supplies = node_supplies.sort_by(&:millicents_per_hour)
    @blender_scene = blender_scene
    @tweaks = tweaks || {}

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

  def job_time
    @estimate.job_time
  end

  private
    def calculate
      # GENERAL
      download_time = @estimate.download_time
      unzip_time = @estimate.unzip_time

      # GENERAL POST RENDERING
      post_render_time = [ @estimate.zip_time, @estimate.encode_time ].max

      # MAX NODES - MIN DEADLINE
      max_node_count = [
        @max_node_count,
        @blender_scene.frames.count / @min_jobs_per_node,
      ].min
      max_node_count = [ max_node_count, 1 ].max
      debug { "MAX NODE COUNT: #{max_node_count}" }

      api_time = @api_time_per_node * max_node_count

      min_wall_time = api_time + @node_boot_time + download_time + unzip_time +
        job_time * (@blender_scene.frames.count / max_node_count) +
        post_render_time
      safe_min_wall_time = min_wall_time * @min_deadline_factor

      @deadline_hours_min = [ @deadline_hours_min,
        safe_min_wall_time.in_hours.ceil ].max
      debug { "MIN DEADLINE: #{@deadline_hours_min}h" }

      # ONE NODE - MAX DEADLINE
      api_time = @api_time_per_node

      all_jobs_time = job_time * @blender_scene.frames.count

      max_wall_time = api_time + @node_boot_time + download_time + unzip_time +
        all_jobs_time + post_render_time
      debug { "MAX WALL TIME (ONE NODE): #{max_wall_time.round}" }
      allowed_max_deadline = max_wall_time * @max_deadline_factor

      @deadline_hours_max = [
        @deadline_hours_min + 1,
        allowed_max_deadline.in_hours.ceil,
      ].max
      debug { "MAX DEADLINE: #{@deadline_hours_max}h" }

      # ACTUAL PREFERRED DEADLINE
      deadline_hours = [ @deadline_hours_max, @tweaks["deadline_hours"] ].min
      deadline_hours = [ @deadline_hours_min, deadline_hours ].max
      debug { "ACTUAL PREFERRED DEADLINE: #{deadline_hours}h" }

      # Figure out how many nodes we need
      deadline = deadline_hours.hours
      a = @api_time_per_node.in_seconds
      j = all_jobs_time.in_seconds
      d = deadline.in_seconds
      b = @node_boot_time.in_seconds
      sqrt_term = (d - b)**2 - 4*a*j
      debug { "SQRT TERM: #{sqrt_term}" }
      if sqrt_term.positive?
        node_count = (d - b - Math.sqrt(sqrt_term)) / (2*a)
        debug { "NODE COUNT FORMULA: #{node_count.round 4}" }
      else
        node_count = j / (d - b)
        debug { "FALL BACK TO SIMPLE FORMULA: #{node_count.round 4}" }
      end
      debug { "NODE COUNT: #{node_count}" }
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
      debug { "AVG NODE HOUR COST: #{avg_node_hour_cost.round 4} cents" }

      # How long do we expect to run the nodes?
      node_time = (@api_time_per_node + @node_boot_time + download_time + unzip_time) *
        node_count + all_jobs_time + post_render_time
      debug { "NODE TIME: #{node_time.round 4}s" }

      node_cost = node_time.in_hours * avg_node_hour_cost
      debug { "NODE COST: #{node_cost.round 4} cents" }

      speed_fac = 1.0 - (deadline_hours - @deadline_hours_min).fdiv(
        @deadline_hours_max - @deadline_hours_min)
      speed_fac = speed_fac ** 1.5
      debug { "SPEED FAC: #{speed_fac.round 4}" }

      margin = speed_fac * @margin_fast + (1 - speed_fac) * @margin_slow
      debug { "MARGIN: #{margin.round 4}" }

      @price_cents = @min_price_cents + (node_cost * margin).ceil
      debug { "PRICE: #{@price_cents} cents" }
    end

    def debug(&message)
      Rails.logger.debug { "[pricing] #{message.call}" }
    end
end
