class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order
      t.references :project
      t.json :settings
      t.integer :price_cents
      t.timestamps
    end
  end
end
