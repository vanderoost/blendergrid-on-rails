class CreateCreditEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_entries do |t|
      t.references :user, null: false
      t.references :order
      t.integer :amount_cents, null: false
      t.string :reason
      t.timestamps
    end
  end
end
