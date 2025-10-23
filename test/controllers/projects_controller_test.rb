require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "it should only return projects in the guest session" do
    project = projects(:guest_project)
    project.update(upload: create_guest_upload)

    get projects_url

    assert_response :success
    assert_match project.name, @response.body
    assert_no_match projects(:richards_project).name, @response.body
    assert_no_match projects(:garys_project).name, @response.body
  end

  test "it should only return projects owned by the logged in user" do
    sign_in_as users(:richard)

    get projects_url

    assert_response :success
    assert_match projects(:richards_project).name, @response.body
    assert_no_match projects(:garys_project).name, @response.body
  end

  private
    def create_guest_upload
      post uploads_url, params: { upload: {
        guest_email_address: "guest@example.com",
        files: [ fixture_file_upload("cube.blend", "application/octet-stream") ],
      } }
      Upload.last
    end
end
