require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest
  test "layout links" do
    get root_path

    # assert_select "a[href=?]", root_path
    # assert_select "a[href=?]", projects_path
    # assert_select "a[href=?]", new_session_path
    # assert_select "a[href=?]", new_registration_path
  end
end
