require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "it should return whether it is in progress or not" do
    project = Project.new

    %w[ created checking benchmarking rendering ].each do |status|
      project.status = status
      assert project.in_progress?, "Project status '#{status}' should be 'in progress'"
    end

    %w[ checked benchmarked rendered cancelled failed ].each do |status|
      project.status = status
      assert_not project.in_progress?,
        "Project status '#{status}' should not be 'in progress'"
    end
  end

  test "project.order should return the latest order when multiple exist" do
    project = projects(:benchmarked)
    user = users(:richard)

    Order.skip_callback(:create, :after, :checkout)

    begin
      abandoned_order = Order.create!(
        user: user,
        cash_cents: project.price_cents,
        credit_cents: 0,
        stripe_session_id: "cs_abandoned_session"
      )
      abandoned_order.items.create!(
        project: project,
        cash_cents: project.price_cents,
        credit_cents: 0,
        preferences: {}
      )
      paid_order = Order.create!(
        user: user,
        cash_cents: project.price_cents,
        credit_cents: 0,
        stripe_session_id: "cs_paid_session",
        stripe_payment_intent_id: "pi_paid_intent"
      )
      paid_order.items.create!(
        project: project,
        cash_cents: project.price_cents,
        credit_cents: 0,
        preferences: {}
      )

      assert paid_order.id > abandoned_order.id,
        "Paid order should have higher ID"
      assert_equal paid_order, project.order,
        "project.order should return latest order (ID #{paid_order.id}), "\
        "not first order (ID #{abandoned_order.id})"
      assert_equal paid_order.items.first, project.order_item,
        "project.order_item should return the latest order item"
    ensure
      Order.set_callback(:create, :after, :checkout)
    end
  end
end
