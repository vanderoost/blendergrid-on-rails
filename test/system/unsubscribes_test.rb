require "application_system_test_case"

class UnsubscribesTest < ApplicationSystemTestCase
  setup do
    @user = users(:gary)
    @token = @user.generate_token_for(:unsubscribe)
  end

  test "the in-email link unsubscribes in one click and can be undone" do
    visit unsubscribe_path(@token)

    # The landing page auto-submits the unsubscribe form via JS.
    assert_text "You're unsubscribed"
    assert @user.reload.marketing_unsubscribed?

    click_button "Re-subscribe"

    assert_text "You're subscribed again"
    assert_not @user.reload.marketing_unsubscribed?
  end
end
