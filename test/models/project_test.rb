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
end
