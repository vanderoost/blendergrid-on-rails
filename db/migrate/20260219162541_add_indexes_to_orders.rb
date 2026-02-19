class AddIndexesToOrders < ActiveRecord::Migration[8.0]
  def change
    add_index :orders, :created_at
    add_index :orders, :guest_email_address
  end
end
