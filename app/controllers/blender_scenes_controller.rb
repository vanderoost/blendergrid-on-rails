class BlenderScenesController < ApplicationController
  include ProjectScoped

  before_action :set_blender_scene, only: %i[ update ]
  allow_unauthenticated_access only: [ :update ]

  def update
    @blender_scene.update(blender_scene_params)
  end

  private
    def blender_scene_params
      params.expect(blender_scene: [ :frame_range_type, :frame_range_start,
        :frame_range_end, :frame_range_step ])
    end

    def set_blender_scene
      @blender_scene = @project.blender_scenes.find(params[:id])
    end
end
