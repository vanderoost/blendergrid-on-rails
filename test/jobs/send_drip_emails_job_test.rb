require "test_helper"

class SendDripEmailsJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = users(:gary) # has gary_subscriber, subscribed
    @cutoff = SendDripEmailsJob::LAUNCH_CUTOFF
  end

  test "sends the day-3 drip once the delay has elapsed" do
    @user.update!(email_address_verified_at: @cutoff + 1.hour)

    travel_to @cutoff + 4.days do
      assert_enqueued_email_with MarketingMailer, :drip_adaptive_sampling,
                                 args: [ @user.subscriber ] do
        SendDripEmailsJob.perform_now
      end
    end
  end

  test "does not re-send a drip already recorded in the Email log" do
    @user.update!(email_address_verified_at: @cutoff + 1.hour)
    Email.create!(
      email_address: @user.email_address,
      mailer_class: "MarketingMailer",
      action: "drip_adaptive_sampling",
    )

    travel_to @cutoff + 4.days do
      assert_no_enqueued_emails { SendDripEmailsJob.perform_now }
    end
  end

  test "skips users verified before the launch cutoff" do
    @user.update!(email_address_verified_at: @cutoff - 1.day)

    travel_to @cutoff + 4.days do
      assert_no_enqueued_emails { SendDripEmailsJob.perform_now }
    end
  end

  test "skips a step that is not yet due" do
    @user.update!(email_address_verified_at: @cutoff + 1.hour)

    travel_to @cutoff + 2.days do
      assert_no_enqueued_emails { SendDripEmailsJob.perform_now }
    end
  end

  test "skips unsubscribed subscribers" do
    @user.update!(email_address_verified_at: @cutoff + 1.hour)
    @user.subscriber.unsubscribe!

    travel_to @cutoff + 4.days do
      assert_no_enqueued_emails { SendDripEmailsJob.perform_now }
    end
  end
end
