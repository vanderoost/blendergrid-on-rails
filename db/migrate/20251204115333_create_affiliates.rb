class CreateAffiliates < ActiveRecord::Migration[8.2]
  def change
    create_table :affiliates do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :landing_page, null: false, foreign_key: true
      t.integer :commission_percent, null: false, default: 10
      t.integer :reward_window_months, null: false, default: 12

      t.timestamps
    end
  end
end
