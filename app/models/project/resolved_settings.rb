class Project::ResolvedSettings
  def initialize(revisions: nil, data: nil)
    @data = data || revisions
      .map { |h| h.deep_symbolize_keys }
      .reduce({}) { |acc, h| acc.deep_merge(h) }
    @cache = {}
  end

  # Helpers
  def frame_range_type
    output.frame_range.type.to_sym
  end
  def frame_range_type
    puts "FRAME RANGE TYPE: #{output.frame_range.type}"
    output.frame_range.type.to_sym
  end
  def frame_count
    if frame_range_type == :animation
      (output.frame_range.start..output.frame_range.end)
        .step(output.frame_range.step).count
    elsif frame_range_type == :image
      1
    else
      raise "Unknown frame range type: #{frame_range_type}"
    end
  end
  def res_x
    (output.format.resolution_x * output.format.resolution_percentage / 100.0).round
  end
  def res_y
    (output.format.resolution_y * output.format.resolution_percentage / 100.0).round
  end
  def spp
    render.sampling.max_samples
  end

  def [](key) = @data[key]

  def method_missing(name, *args)
    return super unless args.empty?

    value = @data[name]
    return wrap_child(name, value) unless value.nil?

    super
  end

  private
    def wrap_child(key, value)
      @cache[key] ||= case value
      when Hash
        self.class.new(data: value)
      when Array
        value.map { |v| v.is_a?(Hash) ? self.class.new(data: v) : v }
      else
        value
      end
    end
end
