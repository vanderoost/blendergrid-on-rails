class CreateNodeSupplies < ActiveRecord::Migration[8.0]
  def change
    create_table :node_supplies do |t|
      t.string :provider_id, null: false
      t.string :region, null: false
      t.string :zone, null: false
      t.string :type_name, null: false
      t.index %i[provider_id region zone type_name], unique: true,
        name: :unique_node_supply_attributes
      t.integer :capacity, default: 0
      t.integer :millicents_per_hour
      t.timestamps
    end
  end
end
