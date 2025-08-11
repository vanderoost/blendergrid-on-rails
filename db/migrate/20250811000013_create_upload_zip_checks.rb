class CreateUploadZipChecks < ActiveRecord::Migration[8.0]
  def change
    create_table :upload_zip_checks do |t|
      t.references :upload
      t.string :status
      t.string :zip_file
      t.json :zip_contents
      t.timestamps
    end
  end
end
