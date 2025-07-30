require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "email addresses should be unique" do
    duplicate = @user.dup
    @user.save
    assert_not duplicate.save
    assert duplicate.errors.include?(:email_address)
  end

  test "email addresses should be saved as lower case" do
    @user.email_address = "TEST@ExAMple.COM"
    @user.save
    assert_equal "test@example.com", @user.reload.email_address
  end

  def setup
    @user = User.new(
      email_address: "test@example.com",
      password: "secretly",
    )
  end
end
