module Statable
  extend ActiveSupport::Concern

  included do
    enum :status, self::STATES.index_with(&:to_s), default: self::STATES.first
    delegate(*self::EVENTS, to: :state)
  end

  private
    def state
      state_class.new(self)
    end

    def state_class
      "#{self.class}::States::#{status.classify}".constantize
    end
end
