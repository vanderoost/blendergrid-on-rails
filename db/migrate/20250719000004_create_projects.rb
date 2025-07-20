class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :uuid, index: { unique: true }
      t.string :main_blend_file
      t.references :upload
      t.timestamps
    end
  end
end
