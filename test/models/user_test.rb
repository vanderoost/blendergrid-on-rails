require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "allows multiple guests with nil email_address" do
    guest1 = User.create!(email_address: nil, guest_email_address: "guest1@example.com")
    guest2 = User.create!(email_address: nil, guest_email_address: "guest2@example.com")

    assert guest1.persisted?
    assert guest2.persisted?
  end

  test "prevents duplicate email addresses at database level" do
    User.create!(email_address: "test@example.com")

    assert_raises(ActiveRecord::RecordInvalid) do
      User.create!(email_address: "test@example.com")
    end
  end
end
