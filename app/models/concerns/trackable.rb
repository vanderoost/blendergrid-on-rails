module Trackable
  extend ActiveSupport::Concern

  included do
    has_many :requests, as: :trackable

    after_commit :track_commit
  end

  private
    def track_commit
      Current.trackable ||= self
    end
end
