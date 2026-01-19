class MaybeRequestWorkersJob < ApplicationJob
  queue_as :default

  def perform(upload)
    upload.maybe_request_workers
  end
end
