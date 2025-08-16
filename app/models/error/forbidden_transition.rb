class Error::ForbiddenTransition < StandardError
  def initialize(state:, event:)
    super "Forbidden event '#{event}' in state '#{state}'."
  end
end
