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
      params.expect(blender_scene: BlenderScene.permitted_params)
    end

    def set_blender_scene
      @blender_scene = @project.blender_scenes.find(params[:id])
    end
end
