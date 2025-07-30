require "test_helper"

class UploadTest < ActiveSupport::TestCase
  test "should be able to save a valid guest upload" do
    assert @guest_upload.save
  end

  test "should be able to save a valid user upload" do
    assert @user_upload.save
  end

  test "guest upload should have files" do
    @guest_upload.files = []
    assert_not @guest_upload.save
    assert @guest_upload.errors.include?(:files)
  end

  test "user upload should have files" do
    @user_upload.files = []
    assert_not @user_upload.save
    assert @user_upload.errors.include?(:files)
  end

  test "guest upload should have a guest email address" do
    @guest_upload.guest_email_address = ""
    assert_not @guest_upload.save
    assert @guest_upload.errors.include?(:guest_email_address)
  end

  test "guest upload should reject invalid guest email addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
      first.last@foo.jp alice+bob@baz.cn foo@bar.fighters]

    valid_addresses.each do |valid_address|
      @guest_upload.guest_email_address = valid_address
      assert @guest_upload.save, "#{valid_address.inspect} should be valid"
    end
  end

  test "email address validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
      foo@bar_baz.com foo@bar+baz.com]

    invalid_addresses.each do |invalid_address|
      @guest_upload.guest_email_address = invalid_address
      assert_not @guest_upload.save, "#{invalid_address.inspect} should be invalid"
      assert @guest_upload.errors.include?(:guest_email_address)
    end
  end

  test "guest upload should have a guest session id" do
    @guest_upload.guest_session_id = nil
    assert_not @guest_upload.save
    assert @guest_upload.errors.include?(:guest_session_id)
  end

  def setup
    @guest_upload = Upload.new(
      guest_email_address: "test@example.com",
      guest_session_id: "1234"
    )
    attach_test_file(@guest_upload)

    @user_upload = Upload.new(user: users(:one))
    attach_test_file(@user_upload)
  end

  def attach_test_file(upload)
    upload.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/cube.blend")),
      filename: "cube.blend",
      content_type: "application/octet-stream"
    )
  end
end
