class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :request, null: false
      t.string :action, null: false
      t.references :resource, polymorphic: true
      t.timestamps
    end
  end
end
