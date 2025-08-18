require "test_helper"

class Project::StatesTest < ActiveSupport::TestCase
  test "a created project can start a blend check" do
    project = projects(:created_project)
    assert project.created?
    project.start_checking
    assert project.checking?
  end

  test "a project can not start a blend check if its state is not created" do
    Project.statuses.except(:created).keys.each do |status|
      project = Project.new(status: status)

      assert_raises(Error::ForbiddenTransition) do
        project.start_checking
      end

      assert_equal project.status, status, "Project status is not #{status}"
    end
  end

  test "a project can finish checking" do
    project = projects(:checking_project)
    assert project.checking?
    project.finish_checking
    assert project.checked?
  end

  test "a checked project can start benchmarking" do
    project = projects(:checked_project)
    assert project.checked?
    project.start_benchmarking
    assert project.benchmarking?
  end

  test "a project can finish benchmarking" do
    project = projects(:benchmarking_project)
    assert project.benchmarking?
    project.finish_benchmarking
    assert project.benchmarked?
  end

  test "a benchmarked project can start rendering" do
    project = projects(:benchmarked_project)
    assert project.benchmarked?
    project.start_rendering
    assert project.rendering?
  end

  test "a project can finish rendering" do
    project = projects(:rendering_project)
    assert project.rendering?
    project.finish_rendering
    assert project.rendered?
  end

  test "a rendering project can be cancelled" do
    project = projects(:rendering_project)
    assert project.rendering?
    project.cancel
    assert project.cancelled?
  end

  test "an active project can fail" do
    project = projects(:created_project)
    active_states.each do |status|
      project.update(status: status)
      project.fail
      assert project.failed?, "Project status is not failed"
    end
  end

  test "a non-active project can not fail or be stopped" do
    Project.statuses.except(*active_states).keys.each do |status|
      project = Project.new(status: status)

      assert_raises(Error::ForbiddenTransition) do
        project.cancel
      end
      assert_raises(Error::ForbiddenTransition) do
        project.fail
      end

      assert_equal project.status, status, "Project status is not #{status}"
    end
  end

  private
    def active_states
      %i[ checking benchmarking rendering ]
    end
end
