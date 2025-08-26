class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :request_data
  attribute :events
  delegate :user, to: :session, allow_nil: true

  def track_event(resource, action: nil)
    self.events ||= []
    self.events << { resource: resource, action: action, created_at: Time.now }
  end
end
