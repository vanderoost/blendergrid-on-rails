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

    assert_equal "test@example.com", Order.last.guest_email_address
    assert_equal "test@example.com", @create_session_params.dig(:customer_email)
  end

  test "should create user order for a single project" do
    sign_in_as users(:verified_user)

    assert_difference("Order.count", 1) do
      post orders_url,
        params: { order: {
            project_uuids: [ @project.uuid ],
          } },
        headers: root_referrer_header
    end
    assert_redirected_to "https://checkout.stripe.com/fake"

    assert Order.last.user.present?
  end

  test "should use render credit with stripe discount if user has a balance" do
    user = users(:user_with_balance_20)
    sign_in_as user

    credit_before = user.render_credit_cents
    assert credit_before > 0, "User has no render credit"

    project_price_cents = @project.price_cents
    assert credit_before < project_price_cents, "Credit should not cover entire amount"

    post orders_url,
      params: { order: {
            project_uuids: [ @project.uuid ],
        } },
      headers: root_referrer_header
    assert_redirected_to "https://checkout.stripe.com/fake"

    user.reload
    credits_used = credit_before - user.render_credit_cents
    assert_equal 2000, credits_used

    line_item = @create_session_params[:line_items].first
    net_amount_cents = line_item[:price_data][:unit_amount]
    assert_equal(project_price_cents, net_amount_cents + credits_used)
  end

  test "should not create a stripe session if credit covers entire amount" do
    user = users(:user_with_balance_1000)
    sign_in_as user

    credit_before = user.render_credit_cents
    project_price_cents = @project.price_cents

    assert_difference("Project::Render.count", 1) do
      post orders_url,
        params: { order: {
            project_uuids: [ @project.uuid ],
          } },
        headers: root_referrer_header
      assert_redirected_to projects_url
    end

    user.reload

    credits_used = credit_before - user.render_credit_cents
    assert_equal project_price_cents, credits_used
  end

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
