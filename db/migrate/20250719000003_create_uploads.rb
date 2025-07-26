class CreateUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :uploads do |t|
      t.string :uuid, index: { unique: true }
      t.json :blend_filepaths
      t.references :user
      t.timestamps
    end
  end
end
