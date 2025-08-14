class CreateLandingPages < ActiveRecord::Migration[8.0]
  def change
    create_table :landing_pages do |t|
      t.string :slug, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
