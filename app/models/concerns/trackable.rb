module Trackable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :resource

    after_create :track_created
    after_update :track_updated
  end

  private
    def track_event(action)
      Current.track_event(self, action: action)
    end

    def track_created
      # track_event(:created)
    end

    def track_updated
      # track_event(:updated)
    end
end
