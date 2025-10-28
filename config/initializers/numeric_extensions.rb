class Numeric
  def milliseconds
    ActiveSupport::Duration.build(self / 1000.0)
  end
  alias_method :millisecond, :milliseconds
end
