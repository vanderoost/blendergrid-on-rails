class CreatePriceCalculations < ActiveRecord::Migration[8.0]
  def change
    create_table :price_calculations do |t|
      t.references :project
      t.string :node_provider
      t.string :node_type
      t.json :sample_settings
      t.json :timing
      t.integer :price_cents
      t.timestamps
    end
  end
end
