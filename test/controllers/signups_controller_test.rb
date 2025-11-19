require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "should get new signups page" do
    get new_signups_url
    assert_response :success
  end

  test "user should submit their name" do
    assert_difference("User.count", 0) do
      post signups_url, params: { signup: {
        name: "",
        email_address: "foo@fighters.bar",
        password: "secretly",
        password_confirmation: "secretly",
        terms: "1",
      } }
    end
    assert_response :unprocessable_entity
  end

  test "user should submit the same password twice" do
    assert_difference("User.count", 0) do
      post signups_url, params: { signup: {
        name: "Nassim Taleb",
        email_address: "foo@fighters.bar",
        password: "secretly",
        password_confirmation: "secretleyyy",
        terms: "1",
      } }
    end
    assert_response :unprocessable_entity
  end

  test "user should accept the terms" do
    assert_difference("User.count", 0) do
      post signups_url, params: { signup: {
        name: "Nassim Taleb",
        email_address: "foo@fighters.bar",
        password: "secretly",
        password_confirmation: "secretly",
        terms: "0",
      } }
    end
    assert_response :unprocessable_entity
  end

  test "should create a new user from a signup" do
    assert_difference("User.count", 1) do
      post signups_url, params: { signup: {
        name: "Nassim Taleb",
        email_address: "foo@fighters.bar",
        password: "secretly",
        password_confirmation: "secretly",
        terms: "1",
      } }
    end
  end

  test "should create a new user with credit from a gift signup" do
    assert_difference("User.count", 1) do
      post signups_url, params: { signup: {
        name: "Youtube Watcher",
        email_address: "yt.watcher@example.com",
        password: "secretly",
        password_confirmation: "secretly",
        terms: "1",
        gift: "true",
      } }
    end

    user = User.last
    assert_equal "yt.watcher@example.com", user.email_address
    assert_equal Signup::GIFT_CENTS, user.render_credit_cents
  end
end
