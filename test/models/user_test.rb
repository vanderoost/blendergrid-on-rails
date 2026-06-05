require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "email addresses should be unique" do
    duplicate = @user.dup
    @user.save
    assert_not duplicate.save
    assert duplicate.errors.key?(:email_address)
  end

  test "email addresses should be saved as lower case" do
    @user.email_address = "TEST@ExAMple.COM"
    @user.save
    assert_equal "test@example.com", @user.reload.email_address
  end

  test "creating a user creates a linked subscriber" do
    @user.save!
    assert @user.subscriber.present?
    assert_equal "signup", @user.subscriber.source
    assert @user.subscriber.subscribed?
  end

  test "creating a user promotes a matching guest subscriber" do
    guest = Subscriber.create!(guest_email_address: @user.email_address, name: "Guest")

    assert_no_difference "Subscriber.count" do
      @user.save!
    end
    assert_equal @user, guest.reload.user
    assert_nil guest.guest_email_address
  end

  def setup
    @user = User.new(
      name: "Test User",
      email_address: "test@example.com",
      password: "secretly",
    )
  end
end
