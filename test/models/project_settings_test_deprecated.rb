require "test_helper"

class ProjectSettingsTest < ActiveSupport::TestCase
  test "project handles one settings revision" do
    project = Project.new
    project.blend_checks.new(settings: { foo: "fighters" })

    assert_equal "fighters", project.settings.foo
  end

  test "project merges multiple settings revisions" do
    project = Project.new
    project.blend_checks.new(settings: { foo: "fighters" })
    project.benchmarks.new(settings: { bar: "bighters" })

    assert_equal "fighters", project.settings.foo
    assert_equal "bighters", project.settings.bar
  end

  test "resolution helpers are working" do
    project = Project.new
    project.blend_checks.new(settings: {
      output: {
        format: {
          resolution_x: 1920,
          resolution_y: 1080,
          resolution_percentage: 50,
        },
        frame_range: { type: "image" },
      },
    })

    assert_equal 960, project.settings.res_x
    assert_equal 540, project.settings.res_y
  end

  test "later settings revision overrides earlier ones" do
    project = Project.new
    project.blend_checks.new(settings: {
      scene_name: "Scene",
      scenes: {
        Scene: {
          resolution: {
            x: 1920,
            y: 1080,
            percentage: 50,
          },
          frame_range: {
            type: "image",
            start: 1001,
            end: 1100,
            single: 1010,
          },
        },
      },
    })
    project.benchmarks.new(settings: {
      scene_name: "Scene",
      scenes: {
        Scene: {
          frame_range: {
            type: "animation",
          },
        },
      },
    })

    assert_equal 960, project.settings.res_x
    assert_equal 540, project.settings.res_y
    assert_equal :animation, project.settings.frame_range_type
  end
end
