class TrackRequestJob < ApplicationJob
  queue_as :default

  def perform(user:, trackable:, request_data:)
    Request.create(
      user: user,
      trackable: trackable,
      **request_data,
    )
  end
end
