require "test_helper"

class SubscribersControllerTest < ActionDispatch::IntegrationTest
  test "new renders the signup form" do
    get new_subscriber_url
    assert_response :success
    assert_select "form"
  end

  test "create adds a guest subscriber with name and email" do
    assert_difference "Subscriber.count", 1 do
      post subscribers_url, params: {
        subscriber: { name: "New Person", guest_email_address: "new@example.com" },
      }
    end
    assert_response :success

    sub = Subscriber.find_by(guest_email_address: "new@example.com")
    assert_nil sub.user
    assert_equal "New Person", sub.name
    assert_equal "newsletter", sub.source
  end

  test "create revives a previously unsubscribed guest instead of duplicating" do
    subscribers(:newsletter_guest).unsubscribe!

    assert_no_difference "Subscriber.count" do
      post subscribers_url, params: {
        subscriber: { name: "Jane", guest_email_address: "jane@example.com" },
      }
    end
    assert subscribers(:newsletter_guest).reload.subscribed?
  end

  test "create links to an existing user instead of creating a guest" do
    post subscribers_url, params: {
      subscriber: { name: "Billy", guest_email_address: users(:billy).email_address },
    }
    assert_response :success
    assert_equal users(:billy), Subscriber.last.user
    assert_nil Subscriber.last.guest_email_address
  end

  test "create rejects an invalid email" do
    assert_no_difference "Subscriber.count" do
      post subscribers_url, params: {
        subscriber: { name: "Bad", guest_email_address: "not-an-email" },
      }
    end
    assert_response :unprocessable_content
  end
end
