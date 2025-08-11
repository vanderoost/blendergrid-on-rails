require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  test "should create guest upload" do
    assert_difference("Upload.count", 1) do
      post uploads_url, params: { upload: {
        guest_email_address: "foo@fighters.bar",
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ],
      } }, headers: root_referrer_header
    end
    assert_redirected_to root_url

    assert Upload.last.user.blank?
    assert Upload.last.guest_email_address == "foo@fighters.bar"
    assert Upload.last.guest_session_id.present?
  end

  test "should create user upload" do
    sign_in_as users(:verified_user)
    assert_difference("Upload.count", 1) do
      post uploads_url, params: { upload: {
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ],
      } }, headers: root_referrer_header
    end
    assert_redirected_to root_url

    assert Upload.last.user.present?
    assert Upload.last.guest_email_address.blank?
    assert Upload.last.guest_session_id.blank?
  end

  test "should pick files" do
    assert_difference("Upload.count", 0) do
      post uploads_url, params: { upload: {
        guest_email_address: "foo@fighters.bar",
      } }, headers: root_referrer_header
    end
    assert_response :unprocessable_content
  end

  test "guests should enter an email address" do
    assert_difference("Upload.count", 0) do
      post uploads_url, params: { upload: {
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ],
      } }, headers: root_referrer_header
    end
    assert_response :unprocessable_content
  end
end
