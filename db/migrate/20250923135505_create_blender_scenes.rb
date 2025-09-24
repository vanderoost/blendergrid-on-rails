class CreateBlenderScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :blender_scenes do |t|
      t.references :project, null: false
      t.string :name
      t.json :frame_range
      t.json :resolution
      t.json :sampling
      t.json :file_output
      t.json :camera
      t.json :post_processing
      t.timestamps
    end
  end
end
