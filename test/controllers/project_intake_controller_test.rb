require "test_helper"

class ProjectIntakeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @upload = uploads(:guest_upload)
  end

  test "should create project intake" do
    assert_difference("Project.count", 1) do
      post upload_project_intakes_url(@upload), params: {
        project_intake: { blend_files: [ @upload.files.first.blob.filename ] },
      }, headers: root_referrer_header
    end
    assert_redirected_to root_url
  end

  test "should choose files" do
    assert_difference("Project.count", 0) do
      post upload_project_intakes_url(@upload), params: {
        project_intake: { blend_files: [] },
      }, headers: root_referrer_header
    end
    assert_response :unprocessable_content
  end

  test "should handle fully empty checkboxes" do
    assert_difference("Project.count", 0) do
      post upload_project_intakes_url(@upload),
        params: {}, headers: root_referrer_header
    end
    assert_response :unprocessable_content
  end
end
