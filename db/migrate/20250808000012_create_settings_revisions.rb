class CreateSettingsRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :settings_revisions do |t|
      t.references :project
      t.json :settings
      t.timestamps
    end
  end
end
