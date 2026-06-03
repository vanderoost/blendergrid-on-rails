require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:gary)
    @token = @user.generate_token_for(:unsubscribe)
  end

  # --- GET show (landing page) ---

  test "show renders the auto-submitting form for a subscribed user" do
    get unsubscribe_url(@token)
    assert_response :success
    assert_select "form[data-controller='submit-on-load']"
    assert_not @user.reload.marketing_unsubscribed?, "GET must not unsubscribe"
  end

  test "show renders the unsubscribed state once unsubscribed" do
    @user.unsubscribe_from_marketing!
    get unsubscribe_url(@token)
    assert_response :success
    assert_select "form[data-controller='submit-on-load']", false
  end

  test "show handles an invalid token without error" do
    get unsubscribe_url("not-a-real-token")
    assert_response :success
  end

  # --- POST create (unsubscribe) ---

  test "create unsubscribes the user" do
    post unsubscribe_url(@token)
    assert_response :success
    assert @user.reload.marketing_unsubscribed?
  end

  test "create works without a CSRF token (RFC 8058 one-click)" do
    # IntegrationTest doesn't send CSRF tokens; this would fail if the controller
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

  # --- DELETE destroy (re-subscribe) ---

  test "destroy re-subscribes the user" do
    @user.unsubscribe_from_marketing!

    delete unsubscribe_url(@token)
    assert_response :success
    assert_not @user.reload.marketing_unsubscribed?
  end

  test "unsubscribe then re-subscribe leaves the user subscribed" do
    post unsubscribe_url(@token)
    assert @user.reload.marketing_unsubscribed?

    delete unsubscribe_url(@token)
    assert_not @user.reload.marketing_unsubscribed?
  end

  test "destroy with an invalid token does not raise" do
    delete unsubscribe_url("not-a-real-token")
    assert_response :success
  end
end
