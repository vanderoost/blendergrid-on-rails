class CreatePriceCalculations < ActiveRecord::Migration[8.1]
  def change
    create_table :price_calculations do |t|
      t.belongs_to :project

      t.json :settings, null: false, default: {}

      t.timestamps
    end
  end
end
