class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.references :user
      t.string :slug, null: false, index: { unique: true }
      t.string :title
      t.text :excerpt
      t.text :body
      t.text :image_url
      t.datetime :published_at
      t.timestamps
    end
  end
end
