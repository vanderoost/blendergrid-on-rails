require "test_helper"
require "ostruct"
require "minitest/mock"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:benchmarked_project)
  end

  test "should create order" do
    Stripe::Checkout::Session.define_singleton_method(:create) do |*args|
      OpenStruct.new(
        id: "cs_test_fake_session_id",
        url: "https://checkout.stripe.com/fake"
      )
    end

    assert_difference("Order.count", 1) do
      post orders_url, params: {
        order: { project_settings: {
            @project.uuid => { "cycles_samples" => "64" },
          } },
      }, headers: root_referrer_header
    end
    assert_response :redirect
  end
end
