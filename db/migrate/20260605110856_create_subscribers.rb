class CreateSubscribers < ActiveRecord::Migration[8.2]
  def change
    create_table :subscribers do |t|
      t.string :name
      t.string :guest_email_address
      t.references :user, foreign_key: true, index: false
      t.datetime :deleted_at
      t.string :source

      t.timestamps
    end

    # A user has at most one subscriber; a guest email is unique among guest rows.
    add_index :subscribers, :user_id, unique: true, where: "user_id IS NOT NULL"
    add_index :subscribers, :guest_email_address,
      unique: true, where: "user_id IS NULL"
    add_index :subscribers, :deleted_at
  end
end
