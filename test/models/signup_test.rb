require "test_helper"

class SignupTest < ActiveSupport::TestCase
  test "should be able to save a valid signup" do
    assert @signup.save
  end

  test "email address should be present" do
    @signup.email_address = ""
    assert_not @signup.save
    assert @signup.errors.include?(:email_address)
  end

  test "email address should not be too long" do
    @signup.email_address = "a" * 256 + "@example.com"
    assert_not @signup.save
    assert @signup.errors.include?(:email_address)
  end

  test "email address validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
      first.last@foo.jp alice+bob@baz.cn foo@bar.fighters]

    valid_addresses.each do |valid_address|
      @signup.email_address = valid_address
      assert @signup.save, "#{valid_address.inspect} should be valid"
    end
  end

  test "email address validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
      foo@bar_baz.com foo@bar+baz.com]

    invalid_addresses.each do |invalid_address|
      @signup.email_address = invalid_address
      assert_not @signup.save, "#{invalid_address.inspect} should be invalid"
      assert @signup.errors.include?(:email_address)
    end
  end

  test "password and confirmation should be present" do
    @signup.password = ""
    @signup.password_confirmation = ""
    assert_not @signup.save
    assert @signup.errors.include?(:password)
  end

  test "password should not be too short" do
    @signup.password = "secret"
    assert_not @signup.save
    assert @signup.errors.include?(:password)
  end

  test "password should not be too long" do
    @signup.password = "a" * 75
    assert_not @signup.save
    assert @signup.errors.include?(:password)
  end

  test "password confirmation should be the same as password" do
    @signup.password_confirmation += "_"
    assert_not @signup.save
    assert @signup.errors.include?(:password_confirmation)
  end

  def setup
    @signup = Signup.new(
      email_address: "test@example.com",
      password: "secretly",
      password_confirmation: "secretly"
    )
  end
end
