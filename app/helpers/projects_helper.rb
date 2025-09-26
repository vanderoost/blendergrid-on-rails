module ProjectsHelper
  def state_title(state)
    case state.to_sym
    when :created then "Ready to check .blend file"
    when :checking then "Checking .blend file"
    when :checked then "Ready to calculate price"
    when :benchmarking then "Calculating price"
    when :benchmarked then "Ready to render"
    when :rendering then "Rendering"
    when :rendered then "Finished Rendering"
    when :cancelled then "Cancelled"
    when :failed then "Failed"
    end
  end

  def frame_description(project)
    if project.current_blender_scene&.frame_range_type == :animation
      human_frame_range project
    elsif project.current_blender_scene&.frame_range_type == :image
      human_single_frame project
    end
  end

  def human_frame_range(project)
    "Frames #{project.current_blender_scene&.frame_range_start} - "\
    "#{project.current_blender_scene&.frame_range_end}"
  end

  def human_single_frame(project)
    "Frame #{project.current_blender_scene&.frame_range_single}"
  end
end
