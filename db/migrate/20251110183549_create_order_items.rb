class CreateOrderItems < ActiveRecord::Migration[8.2]
  def change
    create_table :order_items do |t|
      t.references :order, null: false
      t.references :project, null: false
      t.integer :cash_cents, null: false
      t.integer :credit_cents, null: false
      t.json :preferences
      t.timestamps
    end
  end
end
