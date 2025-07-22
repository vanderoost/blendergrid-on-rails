class CreateNodeSupplies < ActiveRecord::Migration[8.0]
  def change
    create_table :node_supplies do |t|
      t.string :provider
      t.string :region
      t.string :zone
      t.string :node_type
      t.integer :capacity, default: 0
      t.integer :millicents_per_hour
      t.timestamps
    end
  end
end
