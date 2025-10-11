class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :upload
      t.references :current_blender_scene, foreign_key: { to_table: :blender_scenes }
      t.string :uuid, null: false, index: { unique: true }
      t.string :status
      t.string :blend_filepath
      t.integer :render_duration
      t.timestamps
    end
  end
end
