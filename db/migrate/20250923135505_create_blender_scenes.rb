class CreateBlenderScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :blender_scenes do |t|
      t.references :project, null: false
      t.string :name, null: false
      t.json :frame_range, null: false
      t.json :resolution, null: false
      t.json :sampling, null: false
      t.json :file_output, null: false
      t.json :camera, null: false
      t.json :post_processing, null: false
      t.timestamps
    end
  end
end
