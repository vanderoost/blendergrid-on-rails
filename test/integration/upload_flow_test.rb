require "test_helper"

class UploadFlowTest < ActionDispatch::IntegrationTest
  test "guest can upload a blend file" do
    get root_path
    assert_response :success

    assert_difference("Upload.count", 1) do
      post uploads_url, params: { upload: {
        guest_email_address: "guest@foo.bar",
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ]
      } }
    end

    # assert_equal 1, Upload.last.files.count
    # assert Upload.last.guest_session_id.present?
    #
    # follow_redirect!
    # assert_response :success
    #
    # assert_select "turbo-frame#upload_workflow"

    # TODO: Figure out what to exactly test here and how it's different from the
    # UploadsController test.
  end

  # def "user can upload a blend file"
  # end
end
