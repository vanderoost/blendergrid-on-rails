class CreateAffiliateMonthlyStats < ActiveRecord::Migration[8.2]
  def change
    create_table :affiliate_monthly_stats do |t|
      t.references :affiliate, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :visits, null: false, default: 0
      t.integer :signups, null: false, default: 0
      t.integer :sales_cents, null: false, default: 0
      t.integer :rewards_cents, null: false, default: 0
      t.datetime :paid_out_at

      t.timestamps
    end

    add_index :affiliate_monthly_stats,
      [ :affiliate_id, :year, :month ],
      unique: true
  end
end
