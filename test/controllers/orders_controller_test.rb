require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:benchmarked_project)
  end

  test "should create order" do
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
