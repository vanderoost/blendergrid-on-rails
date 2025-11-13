class CreateProjectBenchmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :project_benchmarks do |t|
      t.references :project, null: false
      t.json :sample_settings, null: false
      t.timestamps
    end
  end
end
