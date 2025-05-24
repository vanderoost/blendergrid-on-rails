class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :uuid
      t.string :name
      t.string :main_blend_file
      t.integer :status
      t.json :settings, null: false, default: {}
      t.json :stats, null: false, default: {}
      t.string :stripe_session_id

      t.belongs_to :upload

      t.timestamps
    end
  end
end
