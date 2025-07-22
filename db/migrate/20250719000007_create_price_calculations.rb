class CreatePriceCalculations < ActiveRecord::Migration[8.0]
  def change
    create_table :price_calculations do |t|
      t.references :project
      t.string :node_provider_id
      t.string :node_type_name
      t.json :sample_settings
      t.json :timing
      t.integer :expected_render_time
      t.integer :price_cents
      t.timestamps
    end
  end
end
