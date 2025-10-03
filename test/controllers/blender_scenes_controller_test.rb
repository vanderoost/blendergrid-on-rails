require "test_helper"

class BlenderScenesControllerTest < ActionDispatch::IntegrationTest
  test "it sanitizes int values from string to int" do
    blender_scene = blender_scenes(:one)
    blender_scene.project.update(current_blender_scene_id: blender_scene.id)
    puts blender_scene.project.inspect

    assert_equal 1920, blender_scene.resolution_x

    post edit_project_blender_scene_url(blender_scene.project, blender_scene),
      params: {}
    # params: {
    #   "blender_scene" => {
    #     "frame_range_type" => "image",
    #     "frame_range_start" => "1",
    #     "frame_range_end" => "1",
    #     "frame_range_step" => "1",
    #     "frame_range_single" => "1",
    #     "resolution_x" => "1280",
    #     "resolution_y" => "720",
    #     "resolution_percentage" => "50",
    #     "sampling_use_adaptive" => "0",
    #     "sampling_noise_threshold" => "0.01",
    #     "sampling_min_samples" => "0",
    #     "sampling_max_samples" => "256",
    #     "file_output_file_format" => "PNG",
    #     "file_output_color_mode" => "rgba",
    #     "file_output_color_depth" => "8",
    #     "file_output_film_transparent" => "1",
    #     "camera_name" => "SceneCam",
    #     "post_processing_use_compositing" => "1",
    #     "post_processing_use_sequencer" => "1",
    #     "post_processing_use_stamp" => "0",
    #   },
    #   "commit" => "Save",
    #   "project_uuid" => blender_scene.project.uuid,
    #   "id" => blender_scene.project.id,
    # }

    assert_response :success

    # blender_scene.reload
    # assert_equal 1280, blender_scene.resolution_x
  end
end
