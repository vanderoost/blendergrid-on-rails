class CreateProjectSources < ActiveRecord::Migration[8.0]
  def change
    create_table :project_sources do |t|
      t.string :uuid

      t.timestamps
    end
  end
end
