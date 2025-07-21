class CreatePriceCalculations < ActiveRecord::Migration[8.0]
  def change
    create_table :price_calculations do |t|
      t.references :project
      t.string :node_type
      t.integer :price_cents
      t.json :timing
      t.timestamps
    end
  end
end
