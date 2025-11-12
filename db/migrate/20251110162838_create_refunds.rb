class CreateRefunds < ActiveRecord::Migration[8.2]
  def change
    create_table :refunds do |t|
      t.references :order_item, null: false
      t.integer :amount_cents
      t.string :stripe_refund_id
      t.timestamps
    end
  end
end
