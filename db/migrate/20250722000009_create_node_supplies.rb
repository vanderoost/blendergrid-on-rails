class CreateNodeSupplies < ActiveRecord::Migration[8.0]
  def change
    create_table :node_supplies do |t|
      t.string :provider_id
      t.string :region
      t.string :zone
      t.string :type_name
      t.index %i[provider_id region zone type_name], unique: true,
        name: :unique_node_supply_dimensions
      t.integer :capacity, default: 0
      t.integer :millicents_per_hour
      t.timestamps
    end
  end
end
