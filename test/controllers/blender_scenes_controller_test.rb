require "test_helper"

class BlenderScenesControllerTest < ActionDispatch::IntegrationTest
  test "it sanitizes int values from string to int" do
    blender_scene = blender_scenes(:one)
    blender_scene.project.update(current_blender_scene_id: blender_scene.id)
    puts blender_scene.project.inspect

    assert_equal 1920, blender_scene.resolution_x

    patch project_blender_scene_url(blender_scene.project, blender_scene),
      params: {
        "blender_scene" => {
          "frame_range_type" => "image",
          "frame_range_start" => "1001",
          "frame_range_end" => "1100",
          "frame_range_step" => "1",
          "frame_range_single" => "1010",
          "resolution_x" => "1280",
          "resolution_y" => "720",
          "resolution_percentage" => "50",
          "sampling_use_adaptive" => "1",
          "sampling_noise_threshold" => "0.01",
          "sampling_min_samples" => "0",
          "sampling_max_samples" => "256",
          "file_output_file_format" => "PNG",
          "file_output_color_mode" => "RGBA",
          "file_output_color_depth" => "8",
          "file_output_film_transparent" => "1",
          "camera_name" => "SceneCam",
          "post_processing_use_compositing" => "1",
          "post_processing_use_sequencer" => "1",
          "post_processing_use_stamp" => "0",
        },
        "commit" => "Save",
        "project_uuid" => blender_scene.project.uuid,
        "id" => blender_scene.project.id,
      }

    assert_response :redirect

    blender_scene.reload
    assert_equal 1001, blender_scene.frame_range_start
    assert_equal 1100, blender_scene.frame_range_end
    assert_equal 1, blender_scene.frame_range_step
    assert_equal 1010, blender_scene.frame_range_single
    assert_equal 1280, blender_scene.resolution_x
    assert_equal 720, blender_scene.resolution_y
    assert_equal 50, blender_scene.resolution_percentage
    assert_equal true, blender_scene.sampling_use_adaptive
    assert_equal 0.01, blender_scene.sampling_noise_threshold
    assert_equal 0, blender_scene.sampling_min_samples
    assert_equal 256, blender_scene.sampling_max_samples
    assert_equal "PNG", blender_scene.file_output_file_format
    assert_equal "RGBA", blender_scene.file_output_color_mode
    assert_equal "8", blender_scene.file_output_color_depth
    assert_equal true, blender_scene.file_output_film_transparent
    assert_equal "SceneCam", blender_scene.camera_name
    assert_equal true, blender_scene.post_processing_use_compositing
    assert_equal true, blender_scene.post_processing_use_sequencer
    assert_equal false, blender_scene.post_processing_use_stamp
  end
end
