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

  test "blend_check_errors combines global and current scene errors" do
    project = projects(:three_scenes)
    project.blend_check.workflow.update(result: {
      stats: { errors: {
        global: [ "corrupt file" ],
        scenes: { "Scene-1" => [ "no camera" ], "Scene-2" => [] },
      } },
    })

    assert_equal [ "corrupt file", "no camera" ], project.blend_check_errors
    assert project.has_errors?
  end

  test "has_errors? snaps back when switching to a scene without errors" do
    project = projects(:three_scenes)
    project.blend_check.workflow.update(result: {
      stats: { errors: { scenes: { "Scene-1" => [ "no camera" ] } } },
    })
    assert project.has_errors?

    project.current_blender_scene = blender_scenes(:two_of_three)
    assert_not project.has_errors?
  end

  test "blend_check_errors supports the legacy flat array format" do
    project = projects(:three_scenes)
    project.blend_check.workflow.update(result: {
      stats: { errors: [ "no camera" ] },
    })

    assert_equal [ "no camera" ], project.blend_check_errors
    assert project.has_errors?
  end

  test "blend_check_errors is empty without a blend check result" do
    project = projects(:created)
    assert_equal [], project.blend_check_errors
    assert_not project.has_errors?
  end

  test "project.order should return the latest order when multiple exist" do
    project = projects(:benchmarked)
    user = users(:richard)

    # Stub at method level: skip_callback+set_callback corrupts chain order.
    original_checkout = Order.instance_method(:checkout)
    Order.define_method(:checkout) { }

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
      Order.define_method(:checkout, original_checkout)
    end
  end
end
