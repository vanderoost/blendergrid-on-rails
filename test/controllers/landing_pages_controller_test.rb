require "test_helper"

class LandingPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home page" do
    landing_page = landing_pages(:home)
    get landing_page_url(landing_page)
    assert_response :success
    assert_dom "h1"
  end

  test "should show home page with 404 for nonexisting landing page" do
    get landing_page_url("nonexisting")
    assert_response :not_found
    assert_dom "h1"
  end

  test "should show home page with 404 for any nonexisting page" do
    get "/any/nonexisting/page"
    assert_response :not_found
    assert_dom "h1"
  end
end
