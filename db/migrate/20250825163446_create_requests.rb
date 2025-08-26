class CreateRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :requests do |t|
      t.references :user
      t.string :ip_address
      t.string :method
      t.string :path
      t.json :url_params
      t.json :form_params
      t.string :controller
      t.string :action
      t.integer :status_code
      t.integer :response_time_ms
      t.string :referrer
      t.string :user_agent
      t.string :visitor_id
      t.string :uuid
      t.timestamps
    end

    add_index :requests, :visitor_id
    add_index :requests, :ip_address
    add_index :requests, :created_at
    add_index :requests, :status_code
    add_index :requests, :uuid, unique: true

    add_index :requests, [ :visitor_id, :created_at ]
    add_index :requests, [ :path, :method ]
    add_index :requests, [ :controller, :action ]
  end
end
