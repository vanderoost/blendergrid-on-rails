class AddIndexesForAffiliateStatsPerformance < ActiveRecord::Migration[8.2]
  def change
    # Optimize orders query for affiliate stats calculation
    add_index :orders, [ :user_id, :created_at ],
      name: "index_orders_on_user_id_and_created_at"

    # Optimize credit_entries query for topups in affiliate stats
    add_index :credit_entries, [ :reason, :created_at ],
      name: "index_credit_entries_on_reason_and_created_at"
    add_index :credit_entries, [ :user_id, :reason, :created_at ],
      name: "index_credit_entries_on_user_id_reason_created_at"
  end
end
