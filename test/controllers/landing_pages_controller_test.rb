require "test_helper"

class LandingPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home page" do
    landing_page = landing_pages(:home)
    get landing_page_url(landing_page)
    assert_response :success
  end
end
