class AddReferringAffiliateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :referring_affiliate,
      foreign_key: { to_table: :affiliates }, null: true, index: true
  end
end
