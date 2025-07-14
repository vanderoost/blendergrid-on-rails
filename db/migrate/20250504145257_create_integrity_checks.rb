class CreateIntegrityChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :integrity_checks do |t|
      t.belongs_to :project

      t.timestamps
    end
  end
end
