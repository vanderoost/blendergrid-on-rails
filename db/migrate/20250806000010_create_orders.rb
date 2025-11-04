class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user
      t.string :guest_email_address
      t.string :guest_session_id
      t.string :stripe_session_id
      t.integer :paid_cents
      t.integer :used_credit_cents
      t.timestamps
    end
  end
end
