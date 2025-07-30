require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  test "should get new uploads page" do
    get new_upload_url
    assert_response :success
  end

  test "should create a new guest upload" do
    assert_difference("Upload.count", 1) do
      post uploads_url, params: { upload: {
        guest_email_address: "foo@fighters.bar",
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ]
      } }
    end
    assert_response :redirect
  end

  test "should create a new user upload" do
    sign_in_as users(:verified_user)
    assert_difference("Upload.count", 1) do
      post uploads_url, params: { upload: {
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ]
      } }
    end
    assert_response :redirect
  end
end
