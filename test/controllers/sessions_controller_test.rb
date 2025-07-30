require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new session page" do
    get new_session_url
    assert_response :success
  end

  test "should login user" do
    assert_difference("Session.count", 1) do
      post session_url, params: {
        email_address: "one@example.com", password: "password"
      }
    end
    assert_redirected_to root_url
  end
end
