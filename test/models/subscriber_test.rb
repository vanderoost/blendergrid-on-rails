require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  test "email derives from the user when linked, else the guest field" do
    assert_equal users(:gary).email_address, subscribers(:gary_subscriber).email_address
    assert_equal "jane@example.com", subscribers(:newsletter_guest).email_address
  end

  test "guest email must be unique among guests" do
    dupe = Subscriber.new(guest_email_address: "jane@example.com")
    assert_not dupe.valid?
    assert_includes dupe.errors[:guest_email_address], "has already been taken"
  end

  test "user-linked subscriber needs no guest email" do
    assert Subscriber.new(user: users(:billy)).valid?
  end

  test "subscribed scope excludes soft-deleted rows" do
    sub = subscribers(:newsletter_guest)
    assert_includes Subscriber.subscribed, sub
    sub.unsubscribe!
    assert_not_includes Subscriber.subscribed, sub
  end

  test "unsubscribe! and subscribe! toggle deleted_at" do
    sub = subscribers(:gary_subscriber)
    assert sub.subscribed?

    sub.unsubscribe!
    assert_not sub.subscribed?
    assert_not_nil sub.deleted_at

    sub.subscribe!
    assert sub.subscribed?
    assert_nil sub.deleted_at
  end

  test "unsubscribe token round-trips to the same subscriber" do
    sub = subscribers(:gary_subscriber)
    token = sub.generate_token_for(:unsubscribe)
    assert_equal sub, Subscriber.find_by_token_for(:unsubscribe, token)
  end

  test "import_from_kit links to a matching user" do
    sub = Subscriber.import_from_kit(email: users(:billy).email_address,
first_name: "Bill")
    assert_equal users(:billy), sub.user
    assert_nil sub.guest_email_address
    assert_equal "kit", sub.source
  end

  test "import_from_kit creates a guest when no user matches" do
    sub = Subscriber.import_from_kit(email: "new@example.com", first_name: "New")
    assert_nil sub.user
    assert_equal "new@example.com", sub.guest_email_address
    assert_equal "New", sub.name
  end

  test "import_from_kit is idempotent" do
    assert_difference "Subscriber.count", 1 do
      2.times {
 Subscriber.import_from_kit(email: "once@example.com", first_name: "Once") }
    end
  end

  test "for_subscription revives a previously unsubscribed guest" do
    guest = subscribers(:newsletter_guest)
    guest.unsubscribe!

    revived = Subscriber.for_subscription(email: "jane@example.com",
source: "newsletter")
    assert_equal guest, revived
    assert revived.subscribed?
  end
end
