class CreatePageVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :page_variants do |t|
      t.references :landing_page, null: false
      t.json :sections, null: false
      t.timestamps
    end
  end
end
