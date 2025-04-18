class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :uuid
      t.string :name
      t.string :main_blend_file
      t.integer :status

      t.belongs_to :project_source

      t.timestamps
    end
  end
end
