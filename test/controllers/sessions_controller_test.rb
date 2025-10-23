require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new session page" do
    get new_session_url
    assert_response :success
  end

  test "should login verified users" do
    richard = users(:richard)

    assert_difference("Session.count", 1) do
      post session_url, params: {
        email_address: richard.email_address, password: "password",
      }
    end
    assert_redirected_to root_url
    assert flash.key? :notice
  end

  test "should redirect non-verified users to the verification page" do
    assert_difference("Session.count", 0) do
      post session_url, params: {
        email_address: "two@example.com", password: "password",
      }
    end
    assert_response :redirect
  end

  test "should block wrong credentials" do
    assert_difference("Session.count", 0) do
      post session_url, params: {
        email_address: "two@example.com", password: "wrong-password",
      }
    end
    assert_response :redirect
    assert flash.key? :alert
  end
end
