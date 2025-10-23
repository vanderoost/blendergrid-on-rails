class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :upload
      t.references :current_blender_scene, foreign_key: { to_table: :blender_scenes }
      t.references :order
      t.string :uuid, null: false, index: { unique: true }
      t.string :status
      t.string :blend_filepath
      t.json :tweaks
      t.integer :price_cents
      t.datetime :stage_updated_at
      t.timestamps
    end
  end
end
