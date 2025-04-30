module Project::StateMachine
  extend ActiveSupport::Concern

  included do
    delegate(*Project::States::ACTIONS, to: :state)
  end

  def state
    "Project::States::#{self.status.classify}".constantize.new(self)
  end
end
