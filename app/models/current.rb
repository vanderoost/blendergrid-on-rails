class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :request_data
  attribute :trackable
  delegate :user, to: :session, allow_nil: true
end
