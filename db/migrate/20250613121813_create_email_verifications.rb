class CreateEmailVerifications < ActiveRecord::Migration[8.1]
  def change
    create_table :email_verifications do |t|
      t.string :email_address

      t.timestamps
    end
  end
end
