class AddMarketingUnsubscribedAtToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :marketing_unsubscribed_at, :datetime
  end
end
