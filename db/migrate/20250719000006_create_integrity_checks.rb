class CreateIntegrityChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :integrity_checks do |t|
      t.references :project
      t.json :stats
      t.timestamps
    end
  end
end
