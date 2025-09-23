class Project::ResolvedSettings
  def initialize(revisions: nil, data: nil)
    @data = data || revisions
      .reject(&:blank?)
      .map { |h| h.deep_symbolize_keys }
      .reduce({}) { |acc, h| acc.deep_merge(h) }
    @cache = {}
  end

  def as_json(options = {})
    @data
  end

  def frame_range_type
    if scenes && scene_name
      scene_key = scene_name.to_sym
      if scenes.respond_to?(scene_key)
        scene = scenes.send(scene_key)
      elsif scenes.respond_to?(:[]) && scenes[scene_key]
        scene = wrap_child(scene_key, scenes[scene_key])
      else
        scene = nil
      end
      return nil unless scene&.frame_range&.type
      return :image if scene.frame_range.start == scene.frame_range.end
      scene.frame_range.type.to_sym
    else
      nil
    end
  end
  def start_frame
    # Try new structure first (scenes-based)
    if scenes && scene_name
      scene_key = scene_name.to_sym
      if scenes.respond_to?(scene_key)
        scene = scenes.send(scene_key)
      elsif scenes.respond_to?(:[]) && scenes[scene_key]
        scene = wrap_child(scene_key, scenes[scene_key])
      else
        scene = nil
      end
      scene&.frame_range&.start
    # Fallback to old structure
    else
      output&.frame_range&.start
    end
  end
  def end_frame
    # Try new structure first (scenes-based)
    if scenes && scene_name
      scene_key = scene_name.to_sym
      if scenes.respond_to?(scene_key)
        scene = scenes.send(scene_key)
      elsif scenes.respond_to?(:[]) && scenes[scene_key]
        scene = wrap_child(scene_key, scenes[scene_key])
      else
        scene = nil
      end
      scene&.frame_range&.end
    # Fallback to old structure
    else
      output&.frame_range&.end
    end
  end
  def single_frame
    # Try new structure first (scenes-based)
    if scenes && scene_name
      scene_key = scene_name.to_sym
      if scenes.respond_to?(scene_key)
        scene = scenes.send(scene_key)
      elsif scenes.respond_to?(:[]) && scenes[scene_key]
        scene = wrap_child(scene_key, scenes[scene_key])
      else
        scene = nil
      end
      scene&.frame_range&.single
    # Fallback to old structure
    else
      output&.frame_range&.single
    end
  end
  def frame_count
    return nil unless frame_range_type
    if frame_range_type == :animation
      if scenes && scene_name
        scene_key = scene_name.to_sym
        if scenes.respond_to?(scene_key)
          scene = scenes.send(scene_key)
        elsif scenes.respond_to?(:[]) && scenes[scene_key]
          scene = wrap_child(scene_key, scenes[scene_key])
        else
          scene = nil
        end
        (scene.frame_range.start..scene.frame_range.end)
          .step(scene.frame_range.step).count
      else
        (output.frame_range.start..output.frame_range.end)
          .step(output.frame_range.step).count
      end
    elsif frame_range_type == :image
      1
    else
      raise "Unknown frame range type: #{frame_range_type}"
    end
  end
  def res_x
    # Try new structure first (scenes-based)
    if scenes && scene_name
      scene_key = scene_name.to_sym
      if scenes.respond_to?(scene_key)
        scene = scenes.send(scene_key)
      elsif scenes.respond_to?(:[]) && scenes[scene_key]
        scene = wrap_child(scene_key, scenes[scene_key])
      else
        scene = nil
      end
      return nil unless scene&.resolution&.x && scene&.resolution&.percentage
      (scene.resolution.x * scene.resolution.percentage / 100.0).round
    # Fallback to old structure
    elsif output&.format&.resolution_x && output&.format&.resolution_percentage
      (output.format.resolution_x * output.format.resolution_percentage / 100.0).round
    else
      nil
    end
  end
  def res_y
    # Try new structure first (scenes-based)
    if scenes && scene_name
      scene_key = scene_name.to_sym
      if scenes.respond_to?(scene_key)
        scene = scenes.send(scene_key)
      elsif scenes.respond_to?(:[]) && scenes[scene_key]
        scene = wrap_child(scene_key, scenes[scene_key])
      else
        scene = nil
      end
      return nil unless scene&.resolution&.y && scene&.resolution&.percentage
      (scene.resolution.y * scene.resolution.percentage / 100.0).round
    # Fallback to old structure
    elsif output&.format&.resolution_y && output&.format&.resolution_percentage
      (output.format.resolution_y * output.format.resolution_percentage / 100.0).round
    else
      nil
    end
  end
  def spp
    # Try new structure first (scenes-based)
    if scenes && scene_name
      scene_key = scene_name.to_sym
      if scenes.respond_to?(scene_key)
        scene = scenes.send(scene_key)
      elsif scenes.respond_to?(:[]) && scenes[scene_key]
        scene = wrap_child(scene_key, scenes[scene_key])
      else
        scene = nil
      end
      scene&.sampling&.max_samples
    # Fallback to old structure
    elsif render&.sampling&.max_samples
      render.sampling.max_samples
    else
      nil
    end
  end

  def [](key) = @data[key]

  def each(&block)
    return enum_for(:each) unless block_given?
    @data.each(&block)
  end

  def keys
    @data.keys
  end

  def method_missing(name, *args)
    return super unless args.empty?

    value = @data[name]
    return wrap_child(name, value) unless value.nil?

    nil
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
