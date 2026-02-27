class AddReferralCodeToAffiliates < ActiveRecord::Migration[8.0]
  def change
    change_column_null :affiliates, :landing_page_id, true
    add_column :affiliates, :referral_code, :string
    add_index :affiliates, :referral_code, unique: true
  end
end
