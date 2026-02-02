class CreateFaqs < ActiveRecord::Migration[8.2]
  def change
    create_table :faqs do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.integer :clicks, default: 0, null: false
      t.timestamps
    end
  end
end
