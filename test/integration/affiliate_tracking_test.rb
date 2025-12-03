require "test_helper"

class AffiliateTrackingTest < ActionDispatch::IntegrationTest
  test "visitor views landing page and signs up gets attributed" do
    get landing_page_url(slug: "youtuber")
    assert_response :success
    perform_enqueued_jobs(only: TrackRequestJob)

    page_variant = page_variants(:youtuber_default)
    showed_event = Event.where(resource: page_variant, action: :showed).last
    assert_not_nil showed_event, "PageVariant event should be tracked"

    assert_difference("User.count", 1) do
      post signups_url, params: { signup: {
        name: "Youtube Watcher",
        email_address: "watcher@youtube.com",
        password: "password",
        password_confirmation: "password",
        terms: "1",
      } }
    end

    user = User.last
    assert_equal "watcher@youtube.com", user.email_address
    assert_nil user.page_variant, "page_variant should be nil initially"

    perform_enqueued_jobs(only: TrackRequestJob)
    perform_enqueued_jobs(only: AttributePageVariantJob)

    user.reload
    assert_equal page_variant, user.page_variant,
      "PageVariant should be attributed to User"
  end

  test "first-touch attribution when visitor views multiple pages" do
    get landing_page_url(slug: "youtuber")
    assert_response :success
    perform_enqueued_jobs(only: TrackRequestJob)

    get landing_page_url(slug: "/")
    assert_response :success
    perform_enqueued_jobs(only: TrackRequestJob)

    assert_difference("User.count", 1) do
      post signups_url, params: { signup: {
        name: "Bowser",
        email_address: "bowser@hey.com",
        password: "password",
        password_confirmation: "password",
        terms: "1",
      } }
    end

    user = User.last

    perform_enqueued_jobs(only: TrackRequestJob)
    perform_enqueued_jobs(only: AttributePageVariantJob)

    user.reload
    assert_equal page_variants(:youtuber_default), user.page_variant,
      "First PageVariant should be attributed to User"
  end

  test "no attribution when visitor did not view landing page" do
    assert_difference("User.count", 1) do
      post signups_url, params: { signup: {
        name: "Direct User",
        email_address: "direct@hey.com",
        password: "password",
        password_confirmation: "password",
        terms: "1",
      } }
    end

    user = User.last

    perform_enqueued_jobs(only: TrackRequestJob)
    perform_enqueued_jobs(only: AttributePageVariantJob)

    user.reload
    assert_nil user.page_variant, "No PageVariant should be attributed to User"
  end
end
