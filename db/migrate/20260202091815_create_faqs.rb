class CreateFaqs < ActiveRecord::Migration[8.2]
  def change
    create_table :faqs do |t|
      t.string :question
      t.text :answer
      t.integer :clicks, default: 0
      t.timestamps
    end
  end
end
