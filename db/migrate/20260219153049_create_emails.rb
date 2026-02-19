class CreateEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :emails do |t|
      t.string :email_address, null: false
      t.string :mailer_class,  null: false
      t.string :action,        null: false
      t.timestamps
    end
    add_index :emails, :email_address
    add_index :emails, :created_at
    add_index :emails, [ :email_address, :mailer_class, :action ]
  end
end
