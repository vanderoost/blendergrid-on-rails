require "test_helper"
require "ostruct"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "should create guest order for a single project" do
    assert_difference("Order.count", 1) do
      post orders_url,
        params: {
          order: {
            project_uuids: [ @project.uuid ],
            guest_email_address: "test@example.com",
          },
        },
        headers: root_referrer_header
    end
    assert_redirected_to "https://checkout.stripe.com/fake"

    order = Order.last
    assert_equal "test@example.com", order.guest_email_address
    assert_equal "test@example.com", @create_session_params.dig(:customer_email)
    assert_equal @project.price_cents, order.cash_cents
    assert_equal 0, order.credit_cents

    order_item = order.items.first
    assert_equal @project.order_item, order_item
    assert_equal @project.price_cents, order_item.cash_cents
    assert_equal 0, order_item.credit_cents
  end

  test "should create user cash order for a single project" do
    user = users(:richard)
    sign_in_as user
    assert_equal 0, user.render_credit_cents

    assert_difference("Order.count", 1) do
      post orders_url,
        params: { order: {
            project_uuids: [ @project.uuid ],
          } },
        headers: root_referrer_header
    end
    assert_redirected_to "https://checkout.stripe.com/fake"

    order = Order.last
    assert_equal user, order.user
    assert_equal user.email_address, @create_session_params.dig(:customer_email)
    assert_equal @project.price_cents, order.cash_cents
    assert_equal 0, order.credit_cents

    order_item = order.items.first
    assert_equal @project.order_item, order_item
    assert_equal @project.price_cents, order_item.cash_cents
    assert_equal 0, order_item.credit_cents
  end

  test "should use render credit with stripe discount if user has a balance" do
    user = users(:user_with_balance_20)
    sign_in_as user

    assert_equal 2000, user.render_credit_cents, "User should have $20 credits"
    assert 2000 < @project.price_cents, "Credit should not cover entire amount"

    post orders_url,
      params: { order: {
            project_uuids: [ @project.uuid ],
        } },
      headers: root_referrer_header
    assert_redirected_to "https://checkout.stripe.com/fake"

    order = Order.last
    assert_equal user, order.user
    assert_equal 2000, order.credit_cents
    assert_equal @project.price_cents - 2000, order.cash_cents

    order_item = order.items.first
    assert_equal @project.order_item, order_item
    assert_equal 2000, order_item.credit_cents
    assert_equal @project.price_cents - 2000, order_item.cash_cents
  end

  test "should not create a stripe session if credit covers entire amount" do
    user = users(:user_with_balance_1000)
    sign_in_as user

    assert_equal 100000, user.render_credit_cents, "User should have $1000 credits"
    assert 100000 >= @project.price_cents, "Credit should cover entire amount"

    assert_difference("Project::Render.count", 1) do
      post orders_url,
        params: { order: {
            project_uuids: [ @project.uuid ],
          } },
        headers: root_referrer_header
      assert_redirected_to projects_url
    end

    user.reload
    assert_equal @project.price_cents, 100000 - user.render_credit_cents

    credit_entry = user.credit_entries.last
    assert_equal @project.price_cents, -credit_entry.amount_cents

    order = Order.last
    assert_equal user, order.user
    assert_equal @project.price_cents, order.credit_cents
    assert_equal 0, order.cash_cents

    order_item = order.items.first
    assert_equal @project.order_item, order_item
    assert_equal @project.price_cents, order_item.credit_cents
    assert_equal 0, order_item.cash_cents
  end

  private
    setup do
      @project = projects(:benchmarked)

      test_context = self
      Stripe::Checkout::Session.define_singleton_method(:create) do |params|
        test_context.instance_variable_set(:@create_session_params, params)
        OpenStruct.new(
          id: "cs_test_fake_session_id",
          url: "https://checkout.stripe.com/fake"
        )
      end
    end
end
