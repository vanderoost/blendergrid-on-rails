class SendNewsletterJob < ApplicationJob
  queue_as :default

  # Broadcast fan-out: enqueue one marketing email per subscribed contact (users
  # and guests alike). The mailer skips anyone who unsubscribes in the meantime.
  def perform
    Subscriber.subscribed.find_each do |subscriber|
      MarketingMailer.announcement(subscriber).deliver_later
    end
  end
end
