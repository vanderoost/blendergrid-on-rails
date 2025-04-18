class CreateWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :workflows do |t|
      t.string :uuid
      t.integer :job_type
      t.integer :status

      t.belongs_to :project

      t.timestamps
    end
  end
end
