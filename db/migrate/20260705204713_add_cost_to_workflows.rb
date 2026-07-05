class AddCostToWorkflows < ActiveRecord::Migration[8.2]
  def change
    add_column :workflows, :cost_cents, :integer
  end
end
