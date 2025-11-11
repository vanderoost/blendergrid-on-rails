class CreateRefunds < ActiveRecord::Migration[8.2]
  def change
    create_table :refunds do |t|
      t.references :project, null: false
      t.integer :amount_cents
      t.timestamps
    end
  end
end
