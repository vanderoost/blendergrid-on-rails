class BlenderScenesController < ApplicationController
  include ProjectScoped

  before_action :set_blender_scene, only: %i[ update ]
  allow_unauthenticated_access only: [ :update ]

  def update
    @blender_scene.update(blender_scene_params)
    redirect_to edit_project_path(@project)
  end

  private
    def blender_scene_params
      params.expect(blender_scene: [ :frame_range_type, :frame_range_start,
        :frame_range_end, :frame_range_step, :resolution_x, :resolution_y,
        :resolution_percentage, :sampling_use_adaptive, :sampling_noise_threshold,
        :sampling_min_samples, :sampling_max_samples, :file_output_file_format,
        :file_output_color_mode, :file_output_color_depth, :file_output_ffmpeg_format,
        :file_output_ffmpeg_codec ])
    end

    def set_blender_scene
      @blender_scene = @project.blender_scenes.find(params[:id])
    end
end
