class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.string :token_digest, null: false, index: { unique: true }
      t.string :name, null: false
      t.datetime :last_used_at

      t.timestamps
    end
  end
end
