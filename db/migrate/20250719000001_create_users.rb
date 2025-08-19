class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email_address, null: false, index: { unique: true }
      t.string :password_digest
      t.boolean :email_address_verified, default: false
      t.integer :render_credit_cents, default: 0
      t.timestamps
    end
  end
end
