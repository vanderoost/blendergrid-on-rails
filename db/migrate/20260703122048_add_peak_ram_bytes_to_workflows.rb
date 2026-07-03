class AddPeakRamBytesToWorkflows < ActiveRecord::Migration[8.2]
  def change
    add_column :workflows, :peak_ram_bytes, :integer, limit: 8
  end
end
