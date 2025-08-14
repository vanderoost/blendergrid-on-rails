class CreatePageVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :page_variants do |t|
      t.references :landing_page
      t.json :sections
      t.timestamps
    end
  end
end
