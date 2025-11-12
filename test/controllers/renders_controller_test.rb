require "test_helper"

class RendersControllerTest < ActionDispatch::IntegrationTest
  test "it refunds a cancelled user render paid with credit" do
    user = users(:richard)
    project = projects(:rendering)
    project.upload.update(user: user)

    assert project.renders.any?, "Project has no renders"
    assert project.order_item.present?, "Project has no order item"
    assert project.user.present?, "Project has no user"

    user.update(render_credit_cents: 0)
    project.order_item.update(credit_cents: project.price_cents, cash_cents: 0)
    project.order.update(credit_cents: project.price_cents, cash_cents: 0)

    progress_permil = project.renders.first.workflow.progress_permil

    assert_difference -> { Refund.count } => 1, -> { CreditEntry.count } => 1 do
      delete project_render_url(project, project.renders.first)
    end

    assert_equal "cancelled", project.reload.status

    refund = Refund.last
    assert_equal project, refund.project

    refund_amount = (project.price_cents.fdiv(1000) * (1000-progress_permil)).round
    assert_equal refund_amount, refund.amount_cents

    credit_entry = CreditEntry.last
    assert_equal refund_amount, credit_entry.amount_cents
    assert_equal "credit_refund", credit_entry.reason

    assert_equal refund_amount, user.reload.render_credit_cents
  end

  test "it refunds a cancelled user render paid with cash" do
    user = users(:richard)
    project = projects(:rendering)
    project.upload.update(user: user)

    assert project.renders.any?, "Project has no renders"
    assert project.order_item.present?, "Project has no order item"
    assert project.user.present?, "Project has no user"

    user.update(render_credit_cents: 0)
    project.order_item.update(credit_cents: 0, cash_cents: project.price_cents)
    project.order.update(credit_cents: 0, cash_cents: project.price_cents)

    progress_permil = project.renders.first.workflow.progress_permil

    assert_difference -> { Refund.count } => 1, -> { CreditEntry.count } => 1 do
      delete project_render_url(project, project.renders.first)
    end

    assert_equal "cancelled", project.reload.status

    refund = Refund.last
    assert_equal project, refund.project

    refund_amount = (project.price_cents.fdiv(1000) * (1000-progress_permil)).round
    assert_equal refund_amount, refund.amount_cents

    credit_entry = CreditEntry.last
    assert_equal refund_amount, credit_entry.amount_cents
    assert_equal "delayed_cash_refund", credit_entry.reason

    assert_equal refund_amount, user.reload.render_credit_cents
  end

  test "it refunds a cancelled guest render paid with cash" do
    project = projects(:rendering)

    assert project.renders.any?, "Project has no renders"
    assert project.order_item.present?, "Project has no order item"
    assert project.user.blank?, "Project should have no user"

    project.order_item.update(credit_cents: 0, cash_cents: project.price_cents)
    project.order.update(credit_cents: 0, cash_cents: project.price_cents)

    progress_permil = project.renders.first.workflow.progress_permil

    assert_difference -> { Refund.count } => 1, -> { CreditEntry.count } => 0 do
      delete project_render_url(project, project.renders.first)
    end

    assert_equal "cancelled", project.reload.status

    refund = Refund.last
    assert_equal project, refund.project

    refund_amount = (project.price_cents.fdiv(1000) * (1000-progress_permil)).round
    assert_equal refund_amount, refund.amount_cents

    # TODO: Assert that we have some kind of Stripe TX ID to refund
  end

  test "it refunds a cancelled user render paid with cash and credit" do
    user = users(:richard)
    project = projects(:rendering)
    project.upload.update(user: user)

    assert project.renders.any?, "Project has no renders"
    assert project.order_item.present?, "Project has no order item"
    assert project.user.present?, "Project has no user"

    user.update(render_credit_cents: 0)
    project.order_item.update(
      credit_cents: project.price_cents / 2,
      cash_cents: project.price_cents / 2,
    )
    project.order.update(
      credit_cents: project.price_cents / 2,
      cash_cents: project.price_cents / 2,
    )

    progress_permil = project.renders.first.workflow.progress_permil

    assert_difference -> { Refund.count } => 1, -> { CreditEntry.count } => 2 do
      delete project_render_url(project, project.renders.first)
    end

    assert_equal "cancelled", project.reload.status

    refund = Refund.last
    assert_equal project, refund.project

    refund_amount = (project.price_cents.fdiv(1000) * (1000-progress_permil)).round
    assert_equal refund_amount, refund.amount_cents

    credit_entries = CreditEntry.last(2)
    assert_equal refund_amount / 2, credit_entries.first.amount_cents
    assert_equal refund_amount / 2, credit_entries.last.amount_cents

    assert_equal refund_amount, user.reload.render_credit_cents
  end
end
