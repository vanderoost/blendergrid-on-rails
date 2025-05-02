require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "integrity check can be started when project is uploaded" do
    project = projects(:uploaded)

    assert_enqueued_with(job: Workflows::StartIntegrityCheckJob, args: [ project ]) do
      project.check_integrity
    end

    assert project.checking_integrity?
  end

  test "integrity check can not be started when project is not uploaded" do
    Project.statuses.except(:uploaded).keys.each do |status|
      project = Project.new(status: status)

      assert_raises(Project::States::InvalidTransition) do
        project.check_integrity
      end

      assert project.status == status
    end
  end

  test "price calculation can be started when project has been checked" do
    project = projects(:checked)

    assert_enqueued_with(job: Workflows::StartPriceCalculationJob, args: [ project ]) do
      project.calculate_price
    end

    assert project.calculating_price?
  end

  test "price calculation can not be started when project has not been checked" do
    Project.statuses.except(:checked).keys.each do |status|
      project = Project.new(status: status)

      assert_raises(Project::States::InvalidTransition) do
        project.calculate_price
      end

      assert project.status == status
    end
  end

  test "render can be started when project is waiting" do
    project = projects(:waiting)

    assert_enqueued_with(job: Workflows::StartRenderJob, args: [ project ]) do
      project.start_render
    end

    assert project.rendering?
  end

  test "render can not be started when project is not waiting" do
    Project.statuses.except(:waiting).keys.each do |status|
      project = Project.new(status: status)

      assert_raises(Project::States::InvalidTransition) do
        project.start_render
      end

      assert project.status == status
    end
  end

  test "project status becomes finished when render finishes" do
    project = projects(:rendering)

    project.finish

    assert project.finished?
  end
end
