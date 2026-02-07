class AddStatsToProjectRenders < ActiveRecord::Migration[8.0]
  def change
    change_table :project_renders do |t|
      t.integer :frame_count
      t.integer :resolution_x
      t.integer :resolution_y
      t.integer :pixel_count
      t.integer :max_samples
      t.bigint :total_samples
      t.integer :price_cents
      t.integer :cents_per_gigasample
    end
  end
end
