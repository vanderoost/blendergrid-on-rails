class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :upload
      t.string :uuid, index: { unique: true }
      t.string :status
      t.string :blend_filepath
      t.timestamps
    end
  end
end
