class CreateProjectSources < ActiveRecord::Migration[8.1]
  def change
    create_table :project_sources do |t|
      t.string :uuid

      t.belongs_to :user

      t.timestamps
    end
  end
end
