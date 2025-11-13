class CreateProjectRenders < ActiveRecord::Migration[8.0]
  def change
    create_table :project_renders do |t|
      t.references :project, null: false
      t.timestamps
    end
  end
end
