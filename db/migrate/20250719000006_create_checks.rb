class CreateChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :checks do |t|
      t.references :project
      t.json :stats
      t.timestamps
    end
  end
end
