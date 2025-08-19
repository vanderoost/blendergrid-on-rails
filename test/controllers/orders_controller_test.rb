require "test_helper"
require "ostruct"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:benchmarked)

    Order::Checkout.define_method(:create_stripe_session) do |*args|
      OpenStruct.new(
        id: "cs_test_fake_session_id",
        url: "https://checkout.stripe.com/fake"
      )
    end
  end

  test "should create guest order for a single project" do
    assert_difference("Order.count", 1) do
      post orders_url,
        params: {
          order: {
            project_settings: { @project.uuid => { "cycles_samples" => "64" } },
            guest_email_address: "test@example.com",
          },
        },
        headers: root_referrer_header
    end
    assert_redirected_to "https://checkout.stripe.com/fake"

    assert_equal "test@example.com", Order.last.guest_email_address
  end

  test "should create user order for a single project" do
    sign_in_as users(:verified_user)

    assert_difference("Order.count", 1) do
      post orders_url,
        params: {
          order: {
            project_settings: { @project.uuid => { "cycles_samples" => "64" } },
          },
        },
        headers: root_referrer_header
    end
    assert_redirected_to "https://checkout.stripe.com/fake"

    assert Order.last.user.present?
  end
end
