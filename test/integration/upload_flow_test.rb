require "test_helper"

class UploadFlowTest < ActionDispatch::IntegrationTest
  test "can upload a blend file" do
    get root_path
    assert_response :success

    assert_difference("Upload.count", 1) do
      post uploads_url, params: { upload: {
        guest_email_address: "guest@example.com",
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ]
      } }
      assert_redirected_to upload_path(Upload.last)
    end

    follow_redirect!
    assert_response :success

    # TODO: Figure out what to exactly test here and how it's different from the
    # UploadsController test.
  end
end
