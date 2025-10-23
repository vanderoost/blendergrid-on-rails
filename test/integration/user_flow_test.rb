require "test_helper"

class UserFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "can sign up" do
    get new_signups_path
    assert_response :success

    assert_emails 1 do
      post signups_path, params: { signup: {
        name: "Nassim Taleb",
        email_address: "foo@fighter.bar",
        password: "password",
        password_confirmation: "password",
      } }
      assert_response :redirect
    end

    follow_redirect!
    assert_response :success
  end

  test "can verify email address" do
    user = users(:unverified_user)

    assert_not user.email_address_verified?
    get email_address_verification_path(user.email_address_verification_token)
    assert_response :redirect
    assert user.reload.email_address_verified?

    follow_redirect!
    assert_response :success
    assert flash.key?(:notice)
  end

  test "can log in and out" do
    user = users(:richard)

    get new_session_path
    assert_response :success
    assert cookies[:session_id].blank?

    # Log in
    post session_path, params: {
      email_address: user.email_address, password: "password",
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert flash.key?(:notice)
    assert cookies[:session_id].present?

    # Log out
    delete session_path
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert cookies[:session_id].blank?
  end

  test "send new verification email to unverified users" do
    user = users(:unverified_user)

    assert_emails 1 do
      post session_path, params: {
        email_address: user.email_address, password: "password",
      }
      assert_response :redirect
    end

    follow_redirect!
    assert_response :success
    assert cookies[:session_id].blank?
  end

  test "forgot password sends email" do
    user = users(:richard)

    get new_password_path
    assert_response :success

    assert_emails 1 do
      post passwords_path, params: { email_address: user.email_address }
      assert_response :redirect
    end

    follow_redirect!
    assert_response :success
  end

  test "password can be reset with a valid token" do
    user = users(:richard)
    old_password_digest = user.password_digest

    get edit_password_url(user.password_reset_token)
    assert_response :success

    put password_path(user.password_reset_token), params: {
      password: "new_password",
      password_confirmation: "new_password",
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert flash.key?(:notice)

    assert_not_equal user.reload.password_digest, old_password_digest

    # Log in with the new password
    assert cookies[:session_id].blank?
    post session_path, params: {
      email_address: user.email_address, password: "new_password",
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert flash.key?(:notice)
    assert cookies[:session_id].present?
  end
end
