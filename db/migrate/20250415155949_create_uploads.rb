class CreateUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :uploads do |t|
      t.string :uuid

      t.belongs_to :user

      t.timestamps
    end
  end
end
