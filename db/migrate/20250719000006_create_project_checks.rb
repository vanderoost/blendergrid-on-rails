class CreateProjectChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :project_checks do |t|
      t.references :project
      t.json :stats
      t.timestamps
    end
  end
end
