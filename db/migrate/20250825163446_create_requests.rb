class CreateRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :requests do |t|
      t.references :user
      t.string :ip_address, index: true
      t.string :method
      t.string :path
      t.json :url_params
      t.json :form_params
      t.string :controller
      t.string :action
      t.integer :status_code, index: true
      t.integer :response_time_ms
      t.string :referrer
      t.string :user_agent
      t.string :visitor_id, index: true
      t.string :uuid, index: { unique: true }
      t.timestamps
    end

    add_index :requests, :created_at

    add_index :requests, [ :visitor_id, :created_at ]
    add_index :requests, [ :path, :method ]
    add_index :requests, [ :controller, :action ]
  end
end
