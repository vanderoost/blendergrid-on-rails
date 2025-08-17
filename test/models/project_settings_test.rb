require "test_helper"

class ProjectSettingsTest < ActiveSupport::TestCase
  test "project handles one settings revision" do
    project = Project.new
    project.settings_revisions.new(settings: { foo: "fighters" })

    assert_equal project.settings.foo, "fighters"
  end

  test "project merges multiple settings revisions" do
    project = Project.new
    project.settings_revisions.new(settings: { foo: "fighters" })
    project.settings_revisions.new(settings: { bar: "bighters" })

    assert_equal project.settings.foo, "fighters"
    assert_equal project.settings.bar, "bighters"
  end

  test "resolution helpers are working" do
    project = Project.new
    project.settings_revisions.new(settings: {
      output: {
        format: {
          resolution_x: 1920,
          resolution_y: 1080,
          resolution_percentage: 50,
        },
        output: { frame_range: { type: "image" } },
      },
    })

    assert_equal project.settings.res_x, 960
    assert_equal project.settings.res_y, 540
  end

  test "later settings revision overrides earlier ones" do
    project = Project.new
    project.settings_revisions.new(settings: {
      output: {
        format: {
          resolution_x: 1920,
          resolution_y: 1080,
          resolution_percentage: 50,
        },
        output: { frame_range: { type: "image" } },
      },
    })
    project.settings_revisions.new(settings: {
      output: { frame_range: { type: "animation" } },
    })

    assert_equal project.settings.res_x, 960
    assert_equal project.settings.res_y, 540
    assert_equal project.settings.frame_range_type, :animation
  end
end
