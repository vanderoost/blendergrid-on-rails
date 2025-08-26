class TrackRequestJob < ApplicationJob
  queue_as :default

  def perform(user:, request_data:, events:)
    request = Request.create(
      user: user,
      **request_data,
    )

    events.each do |event_data|
      request.events.create(**event_data)
    end
  end
end
