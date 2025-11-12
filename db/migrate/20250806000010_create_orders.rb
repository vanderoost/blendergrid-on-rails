class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user
      t.string :guest_email_address
      t.string :guest_session_id
      t.string :stripe_session_id
      t.string :stripe_payment_intent_id
      t.integer :cash_cents
      t.integer :credit_cents
      t.timestamps
    end
  end
end
