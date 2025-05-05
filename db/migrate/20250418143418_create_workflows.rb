class CreateWorkflows < ActiveRecord::Migration[8.1]
  def change
    create_table :workflows do |t|
      t.string :uuid
      t.integer :job_type
      t.integer :status
      t.json :timing, null: false, default: {}

      t.belongs_to :project

      t.timestamps
    end
  end
end
