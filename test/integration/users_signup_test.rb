require "test_helper"

class UsersSignupTest < ActionDispatch::IntegrationTest
  test "user can't sign up with invalid data" do
    get signup_path
    assert_no_difference "User.count" do
      post users_path, params: { user: { email: "gary@invalid", password: "invalid*" } }
      assert_response :unprocessable_entity
      assert_select 'form[action="/users"]'
    end
  end
end
