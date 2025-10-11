module HasSceneSettings
  extend ActiveSupport::Concern

  included do
    has_many :blender_scenes
    belongs_to :current_blender_scene, class_name: "BlenderScene", optional: true

    delegate :frames, to: :current_blender_scene
    delegate :scaled_resolution_x, to: :current_blender_scene
    delegate :scaled_resolution_y, to: :current_blender_scene

    BlenderScene::STORE_ACCESSORS.each do |store, attributes|
      attributes.keys.map do |attr|
        delegate "#{store}_#{attr}".to_sym, to: :current_blender_scene, allow_nil: true
      end
    end
  end
end
