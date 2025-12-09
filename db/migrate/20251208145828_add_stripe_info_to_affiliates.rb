class AddStripeInfoToAffiliates < ActiveRecord::Migration[8.2]
  def change
    add_column :affiliates, :stripe_account_id, :string
    add_index :affiliates, :stripe_account_id, unique: true
    add_column :affiliates, :payout_onboarded_at, :datetime
    add_column :affiliates, :payout_method_details, :json
  end
end
