require "test_helper"

class ProjectSettingsTest < ActiveSupport::TestCase
  test "project has check settings" do
    project = Project.new
    project.checks.new.build_workflow(settings: { foo: "fighters" })

    assert project.settings.foo == "fighters"
  end

  test "project merges check and quote settings" do
    project = Project.new
    project.checks.new.build_workflow(settings: { foo: "fighters" })
    project.quotes.new.build_workflow(settings: { bar: "bighters" })

    assert project.settings.foo == "fighters"
    assert project.settings.bar == "bighters"
  end

  test "project merges check and render settings" do
    project = Project.new
    project.checks.new.build_workflow(settings: { foo: "fighters" })
    project.renders.new.build_workflow(settings: { bar: "bighters" })

    assert project.settings.foo == "fighters"
    assert project.settings.bar == "bighters"
  end

  test "project merges check, quote and render settings" do
    project = Project.new
    project.checks.new.build_workflow(settings: { foo: "fighters" })
    project.quotes.new.build_workflow(settings: { bar: "bighters" })
    project.renders.new.build_workflow(settings: { baz: "bighterz" })

    assert project.settings.foo == "fighters"
    assert project.settings.bar == "bighters"
    assert project.settings.baz == "bighterz"
  end

  test "resolution helpers are working" do
    project = Project.new
    project.checks.new.build_workflow(settings: {
      output: {
        format: {
          resolution_x: 1920,
          resolution_y: 1080,
          resolution_percentage: 50
        },
        output: { frame_range: { type: "image" } }
      }
    })

    assert project.settings.res_x == 960
    assert project.settings.res_y == 540
  end

  test "quote overrides check settings" do
    project = Project.new
    project.checks.new.build_workflow(settings: {
      output: {
        format: {
          resolution_x: 1920,
          resolution_y: 1080,
          resolution_percentage: 50
        },
        output: { frame_range: { type: "image" } }
      }
    })
    project.quotes.new.build_workflow(settings: {
      output: { frame_range: { type: "animation" } }
    })

    assert project.settings.res_x == 960
    assert project.settings.res_y == 540
    assert project.settings.frame_range_type == :animation
  end
end
