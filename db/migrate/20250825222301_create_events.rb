class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :request
      t.string :action
      t.references :resource, polymorphic: true
      t.timestamps
    end
  end
end
