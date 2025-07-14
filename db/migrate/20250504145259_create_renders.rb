class CreateRenders < ActiveRecord::Migration[8.1]
  def change
    create_table :renders do |t|
      t.belongs_to :project

      t.timestamps
    end
  end
end
