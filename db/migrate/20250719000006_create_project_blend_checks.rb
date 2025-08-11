class CreateProjectBlendChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :project_blend_checks do |t|
      t.references :project
      t.json :stats
      t.timestamps
    end
  end
end
