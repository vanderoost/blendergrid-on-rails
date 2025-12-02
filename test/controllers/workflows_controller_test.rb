require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "should handle failed workflow" do
    patch api_v1_workflow_path(@blend_check_workflow),
      params: {
        workflow: { status: "failed" },
      },
      headers: @auth_headers,
      as: :json

    @blend_check_workflow.reload
    assert_equal "failed", @blend_check_workflow.status

    project = @blend_check_workflow.project
    assert_equal "failed", project.status
  end

  test "should set status, result, timing, and node type" do
    patch api_v1_workflow_path(@blend_check_workflow),
      params: {
        workflow: {
          status: "finished",
          result: { "foo" => "fight" },
          timing: { "init" => 134 },
        },
      },
      headers: @auth_headers,
      as: :json

    @blend_check_workflow.reload
    assert_equal("finished", @blend_check_workflow.status)
    assert_equal({ "foo" => "fight" }, @blend_check_workflow.result)
    assert_equal({ "init" => 134 }, @blend_check_workflow.timing)
  end

  test "blend check completion should change the project status to checked" do
    assert @checking_project.checking?, "status should be checking"

    patch api_v1_workflow_path(@blend_check_workflow),
      params: {
        workflow: {
          status: "finished",
          result: { settings: {
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
            scene_name: "foo" },
          },
          timing: { "init" => 134 },
          node_provider_id: "aws",
          node_type_name: "t3.micro",
        },
      },
      headers: @auth_headers,
      as: :json

    @checking_project.reload
    assert @checking_project.checked?, "status should be checked"
  end

  test "benchmark completion should change the project status to benchmarked" do
    assert @benchmarking_project.benchmarking?, "status should be benchmarking"

    patch api_v1_workflow_path(@benchmark_workflow),
      params: {
        workflow: {
          status: "finished",
          result: { "settings" => { "foo" => "bar" } },
          timing: {
            "download" => { "max" => 10000 },
            "unzip" => { "max" => 3000 },
            "init" => { "mean" => 5000, "std" => 1000 },
            "sampling" => { "mean" => 120000, "std" => 10000 },
            "post" => { "mean" => 2000, "std" => 500 },
            "upload" => { "mean" => 3000, "std" => 800, "max" => 4000 },
          },
          node_provider_id: "aws",
          node_type_name: "t3.micro",
        },
      },
      headers: @auth_headers,
      as: :json

    @benchmark_workflow.reload
    assert_equal "aws", @benchmark_workflow.node_provider_id
    assert_equal "t3.micro", @benchmark_workflow.node_type_name

    @benchmarking_project.reload
    assert @benchmarking_project.benchmarked?, "status should be benchmarked"
  end

  test "benchmark completion should send a notification email" do
    assert @benchmarking_project.benchmarking?, "status should be benchmarking"

    # richard = users(:richard)
    # @benchmarking_project.upload.user = richard
    # puts "Project user: #{@benchmarking_project.user.email_address}"

    assert_emails 1 do
      patch api_v1_workflow_path(@benchmark_workflow),
        params: {
          workflow: {
            status: "finished",
            result: { "settings" => { "foo" => "bar" } },
            timing: {
              "download" => { "max" => 10000 },
              "unzip" => { "max" => 3000 },
              "init" => { "mean" => 5000, "std" => 1000 },
              "sampling" => { "mean" => 120000, "std" => 10000 },
              "post" => { "mean" => 2000, "std" => 500 },
              "upload" => { "mean" => 3000, "std" => 800, "max" => 4000 },
            },
            node_provider_id: "aws",
            node_type_name: "t3.micro",
          },
        },
        headers: @auth_headers,
        as: :json
    end
  end

  test "render completion should change the project status to rendered" do
    assert @rendering_project.rendering?, "status should be rendering"

    patch api_v1_workflow_path(@render_workflow),
      params: {
        workflow: { status: "finished" },
      },
      headers: @auth_headers,
      as: :json

    @rendering_project.reload
    assert @rendering_project.rendered?, "status should be rendered"
  end

  setup do
    @checking_project = projects(:checking)
    @blend_check_workflow = @checking_project.blend_check.workflow
    @benchmarking_project = projects(:benchmarking)
    @benchmark_workflow = @benchmarking_project.benchmark.workflow
    @rendering_project = projects(:rendering)
    @render_workflow = @rendering_project.render.workflow
    @api_token = ApiToken.create!(name: "Test Token")
    @auth_headers = { "Authorization" => "Bearer #{@api_token.token}" }
  end
end
