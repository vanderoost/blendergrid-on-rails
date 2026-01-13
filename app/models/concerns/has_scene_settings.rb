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

    def settings_hash
      scene_name = current_blender_scene.name
      scenes = blender_scenes.to_h { |scene| [ scene.name, scene.settings_hash ] }
      if tweaks.present? && scenes[scene_name].present?
        scenes[scene_name][:sampling]["max_samples"] =
          tweaks["sampling_max_samples"] if tweaks["sampling_max_samples"]
        scenes[scene_name][:resolution]["percentage"] =
          tweaks["resolution_percentage"] if tweaks["resolution_percentage"]
      end
      { scene_name: scene_name, scenes: scenes }
    end
  end
end
