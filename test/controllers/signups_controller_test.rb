require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "should get new signups page" do
    get new_signups_url
    assert_response :success
  end

  test "should create a new user from a signup" do
    assert_difference("User.count", 1) do
      post signups_url, params: { signup: {
        name: "Nassim Taleb",
        email_address: "foo@fighters.bar",
        password: "secretly",
        password_confirmation: "secretly",
      } }
    end
    assert_response :redirect
    assert flash.key? :notice
  end
end
