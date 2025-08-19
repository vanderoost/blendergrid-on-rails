class CreateWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :workflows do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.string :status
      t.json :result
      t.json :timing

      # TODO: Consider creating a NodeType model and referencing that
      t.string :node_provider_id
      t.string :node_type_name

      t.references :workflowable, polymorphic: true
      t.timestamps
    end
  end
end
