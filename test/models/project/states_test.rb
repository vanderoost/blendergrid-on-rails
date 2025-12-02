require "test_helper"
require "ostruct"

class Project::StatesTest < ActiveSupport::TestCase
  test "a created project can start a blend check" do
    project = projects(:created)
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
    project = projects(:checking)
    assert project.checking?

    project.blend_check.workflow.update(result: {
      settings: {
        scenes: { "foo" => {
          frame_range: {
            type: "animation",
            start: 10,
            end: 250,
            step: 1,
            single: 25,
          },
          resolution: {
            x: 1920,
            y: 1080,
            percentage: 50,
            use_border: false,
          },
          sampling: {
            use_adaptive: true,
            noise_threshold: 0.05,
            min_samples: 16,
            max_samples: 256,
          },
          file_output: {
            file_format: "EXR",
            color_mode: "RGBA",
            color_depth: "16",
            ffmpeg_format: "MP4",
            ffmpeg_codec: "H264",
            film_transparent: true,
            fps: 60,
          },
          camera: {
            name: "Camera",
            name_options: [ "Camera", "Camera.001", "Camera.002" ],
          },
          post_processing: {
            use_compositing: true,
            use_sequencer: false,
            use_stamp: false,
          },
        } },
        scene_name: "foo",
      },
    })

    project.finish_checking
    assert project.checked?
  end

  test "a checked project can start benchmarking" do
    project = projects(:checked)
    assert project.checked?
    project.start_benchmarking
    assert project.benchmarking?
  end

  test "a project can finish benchmarking" do
    project = projects(:benchmarking)
    assert project.benchmarking?

    # Give the benchmark workflow some data to pretend it finished
    finished_workflow = workflows(:finished_benchmark)
    project.benchmark.workflow.delete
    project.benchmark.workflow = finished_workflow
    project.benchmark.save!

    project.finish_benchmarking
    assert project.benchmarked?
  end

  test "a benchmarked project can start rendering" do
    project = projects(:benchmarked)
    assert project.benchmarked?
    project.start_rendering
    assert project.rendering?
  end

  test "a project can finish rendering" do
    project = projects(:rendering)
    assert project.rendering?
    project.finish_rendering
    assert project.rendered?
  end

  test "a rendering project can be cancelled" do
    project = projects(:rendering)
    assert project.rendering?
    project.cancel
    assert project.cancelled?
  end

  test "an active project can fail" do
    project = projects(:created)
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

    setup do
      test_context = self
      Stripe::Refund.define_singleton_method(:create) do |params|
        test_context.instance_variable_set(:@create_refund_params, params)
        OpenStruct.new(id: "fake_refund_id")
      end
    end
end
