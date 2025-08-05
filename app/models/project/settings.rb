class Project::Settings
  def initialize(data:)
    @data = (data || {}).deep_symbolize_keys
    deep_freeze!(@data)
    @memo = {}
  end

  def to_h
    deep_dup(@data)
  end

  def empty?
    @layers.empty?
  end

  def [](key) = @data[key]

  def method_missing(name, *args)
    return super unless args.empty?

    value = @data[name]
    return wrap_child(name, value) unless value.nil?

    super
  end

  def respond_to_missing?(name, include_private = false)
    @data.key?(name) || super
  end

  def frame_range_type
    output.frame_range.type.to_sym
  end

  def frame_count
    if frame_range_type == :animation
      @frame_count ||= (output.frame_range.start..output.frame_range.end)
      .step(output.frame_range.step).count
    elsif frame_range_type == :single_frame
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

  private
    def wrap_child(key, value)
      @memo[key] ||= case value
      when Hash
        self.class.new(data: value)
      when Array
        value.map { |v| v.is_a?(Hash) ? self.class.new(data: v) : v }
      else
        value
      end
    end

    def deep_freeze!(obj)
      case obj
      when Hash
        obj.each { |k, v| deep_freeze!(k); deep_freeze!(v) }
      when Array
        obj.each { |v| deep_freeze!(v) }
      end
      obj.freeze
    end

    def deep_dup(obj)
      case obj
      when Hash
        obj.transform_values { |v| deep_dup(v) }
      when Array
        obj.map { |v| deep_dup(v) }
      else
        obj
      end
    end
end
