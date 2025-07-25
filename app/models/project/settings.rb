class Project::Settings
  def initialize(snapshots:)
    @layers = snapshots.compact.map { |h| h.deep_symbolize_keys }
    @memo   = {}
  end

  def to_h
    @layers.reduce(&:deep_merge)
  end

  def [](key)
    @layers.reverse_each { |layer| return layer[key] if layer.key?(key) }
    nil
  end

  def method_missing(name, *args, &blk)
    return super unless args.empty? && blk.nil?

    value = self[name]
    return wrap_child(name, value) unless value.nil?

    super
  end

  def frame_count
    @frame_count ||= (output.frame_range.start..output.frame_range.end)
      .step(output.frame_range.step).count
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
        self.class.new(snapshots: [ value ])
      when Array
        value.map { |v| v.is_a?(Hash) ? self.class.new(snapshots: [ v ]) : v }
      else
        value
      end
    end
end
