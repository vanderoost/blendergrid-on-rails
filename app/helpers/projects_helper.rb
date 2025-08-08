module ProjectsHelper
  def state_title(state)
    case state.to_sym
    when :uploaded then "Ready to check .blend file"
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
end
