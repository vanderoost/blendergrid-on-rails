class ReplaceEmailAddressVerifiedWithTimestamp < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :email_address_verified_at, :datetime

    # Backfill: we never recorded the real verification time, and every existing
    # verified user is far older than any onboarding window, so created_at is a
    # safe, stable, in-the-past proxy. Unverified rows stay NULL.
    execute(<<~SQL.squish)
      UPDATE users
      SET email_address_verified_at = created_at
      WHERE email_address_verified
    SQL

    remove_column :users, :email_address_verified
  end

  def down
    add_column :users, :email_address_verified, :boolean, default: false

    true_literal = ActiveRecord::Base.connection.quoted_true
    execute(
      "UPDATE users SET email_address_verified = #{true_literal} " \
      "WHERE email_address_verified_at IS NOT NULL"
    )

    remove_column :users, :email_address_verified_at
  end
end
