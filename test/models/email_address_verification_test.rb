require "test_helper"

class EmailAddressVerificationTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "should send a confirmation email" do
    assert_emails 1 do
      EmailAddressVerification.new(users(:unverified_user)).save
    end
  end
end
