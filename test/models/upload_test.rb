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
    assert @guest_upload.errors.key?(:files)
  end

  test "user upload should have files" do
    @user_upload.files = []
    assert_not @user_upload.save
    assert @user_upload.errors.key?(:files)
  end

  test "guest upload should have a guest email address" do
    @guest_upload.guest_email_address = ""
    assert_not @guest_upload.save
    assert @guest_upload.errors.key?(:guest_email_address)
  end

  test "guest upload should have a guest session id" do
    @guest_upload.guest_session_id = nil
    assert_not @guest_upload.save
    assert @guest_upload.errors.key?(:guest_session_id)
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
