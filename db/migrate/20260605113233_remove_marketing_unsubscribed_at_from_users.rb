class RemoveMarketingUnsubscribedAtFromUsers < ActiveRecord::Migration[8.2]
  def change
    remove_column :users, :marketing_unsubscribed_at, :datetime
  end
end
