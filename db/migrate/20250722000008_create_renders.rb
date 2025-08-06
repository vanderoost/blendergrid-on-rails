class CreateRenders < ActiveRecord::Migration[8.0]
  def change
    create_table :renders do |t|
      t.references :project
      t.string :status
      t.timestamps
    end
  end
end
