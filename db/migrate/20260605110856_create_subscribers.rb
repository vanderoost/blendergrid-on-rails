class CreateSubscribers < ActiveRecord::Migration[8.2]
  def change
    create_table :subscribers do |t|
      t.string :name
      t.string :guest_email_address,
        index: { unique: true, where: "user_id IS NULL" }
      t.references :user, foreign_key: true,
        index: { unique: true, where: "user_id IS NOT NULL" }
      t.datetime :deleted_at, index: true
      t.string :source

      t.timestamps
    end
  end
end
