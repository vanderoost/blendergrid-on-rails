require "test_helper"

class ProjectSourcesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get project_sources_create_url
    assert_response :success
  end
end
