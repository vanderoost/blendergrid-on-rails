class CreatePriceCalculations < ActiveRecord::Migration[8.1]
  def change
    create_table :price_calculations do |t|
      t.belongs_to :project

      t.timestamps
    end
  end
end
