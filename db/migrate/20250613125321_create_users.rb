class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: true
      t.string :password_digest, null: true

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
