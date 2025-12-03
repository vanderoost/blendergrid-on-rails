class AddPageVariantToUsers < ActiveRecord::Migration[8.2]
  def change
    add_reference :users, :page_variant, foreign_key: true, index: true
  end
end
