class CreateLandingPages < ActiveRecord::Migration[8.0]
  def change
    create_table :landing_pages do |t|
      t.string :slug, null: false
      t.timestamps
    end

    add_index :landing_pages, :slug, unique: true
  end
end
