require "test_helper"

class UnsubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:gary)
    @token = @user.generate_token_for(:unsubscribe)
  end

  test "show renders the confirmation page for a valid token" do
    get unsubscribe_url(@token)
    assert_response :success
    assert_not @user.reload.marketing_unsubscribed?, "GET must not unsubscribe"
  end

  test "show handles an invalid token without error" do
    get unsubscribe_url("not-a-real-token")
    assert_response :success
  end

  test "create unsubscribes the user" do
    post unsubscribe_url(@token)
    assert_response :success
    assert @user.reload.marketing_unsubscribed?
  end

  test "create works without a CSRF token (one-click)" do
    # IntegrationTest doesn't send CSRF tokens; this would fail if the action
    # weren't exempt from forgery protection.
    post unsubscribe_url(@token)
    assert_response :success
  end

  test "create is idempotent and keeps the original timestamp" do
    @user.unsubscribe_from_marketing!
    original = @user.reload.marketing_unsubscribed_at

    post unsubscribe_url(@token)
    assert_response :success
    assert_equal original, @user.reload.marketing_unsubscribed_at
  end

  test "create with an invalid token does not raise" do
    post unsubscribe_url("not-a-real-token")
    assert_response :success
  end
end
