class Pricing::JobEstimate
  GPU_MAX_RAM_GB = 80
  GPU_SAMPLING_SPEEDUP = 5.0
  GPU_INIT_SLOWDOWN = 3.0
  GPU_PRICE_FAC = 2.5
  UNKNOWN_RAM_GB = 128

  def initialize(benchmark:, blender_scene:, tweaks: {})
    raise "No Benchmark provided" if benchmark.blank?
    raise "No BlenderScene provided" if blender_scene.blank?

    @benchmark = benchmark
    @timing = benchmark.workflow.timing
    @blender_scene = blender_scene
    @tweaks = tweaks || {}
  end

  def download_time
    @timing.dig("download", "max").milliseconds
  end

  def unzip_time
    (@timing.dig("unzip", "max") || 0).milliseconds
  end

  def upload_time
    @timing.dig("upload", "max").milliseconds
  end

  def cpu_init_time
    stat_time("init")
  end

  def gpu_init_time
    ActiveSupport::Duration.build(stat_time("init") * GPU_INIT_SLOWDOWN)
  end

  def init_time
    @init_time ||= use_gpu? ? gpu_init_time : cpu_init_time
  end

  def cpu_sampling_time
    ActiveSupport::Duration.build(stat_time("sampling") * sample_factor)
  end

  def gpu_sampling_time
    ActiveSupport::Duration.build(
      stat_time("sampling") * sample_factor / GPU_SAMPLING_SPEEDUP
    )
  end

  def sampling_time
    @sampling_time ||= use_gpu? ? gpu_sampling_time : cpu_sampling_time
  end

  def post_time
    @post_time ||= ActiveSupport::Duration.build(stat_time("post") * pixel_factor)
  end

  def use_gpu?
    cpu_time = cpu_init_time + cpu_sampling_time + upload_time + post_time
    gpu_time = gpu_init_time + gpu_sampling_time + upload_time + post_time

    Rails.logger.info("Job time - CPU: #{cpu_time} - GPU: #{gpu_time}")

    required_ram = @benchmark.workflow.peak_ram_bytes || UNKNOWN_RAM_GB.gigabytes

    cpu_time > gpu_time * GPU_PRICE_FAC && required_ram < GPU_MAX_RAM_GB.gigabytes
  end

  def job_time
    init_time + sampling_time + post_time + upload_time
  end

  def zip_time
    (@blender_scene.frames.count * orig_pixel_count).fdiv(50_000).round.milliseconds
  end

  def encode_time
    (@blender_scene.frames.count * orig_pixel_count).fdiv(50_000).round.milliseconds
  end

  private
    def stat_time(stage)
      (@timing.dig(stage, "mean") + @timing.dig(stage, "std")).milliseconds
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
