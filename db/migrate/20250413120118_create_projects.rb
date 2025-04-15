class CreateProjects < ActiveRecord::Migration[8.0]
  # def change
  #   create_table :project_sources do |t|
  #     t.string :uuid
  #
  #     t.timestamps
  #   end
  # end

  def change
    create_table :projects do |t|
      t.string :uuid
      t.string :name
      t.belongs_to :project_source

      t.timestamps
    end
  end
end
