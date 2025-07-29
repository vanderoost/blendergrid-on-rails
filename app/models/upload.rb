require "zip"

class Upload < ApplicationRecord
  include Uuidable

  belongs_to :user
  has_many_attached :files
  has_many :projects

  after_create :analyze_zip_files

  def new_project_batch(blend_filepaths)
    ProjectBatch.new(upload: self, blend_filepaths:)
  end

  def blend_files
    files.select { |file|
      file.blob.filename.extension == "blend"
    }
  end

  def zip_files
    files.select { |file|
      file.blob.filename.extension == "zip"
    }
  end

  private
    def analyze_zip_files
      zip_files.each do |zip_file|
        blend_entries = Zip::File.open_buffer(zip_file.blob.download)
          .select { |entry| is_blend_entry? entry }
        zip_file.blob.metadata[:blend_filepaths] = blend_entries.map(&:name)
        zip_file.blob.save
      end
    end
end

def is_blend_entry?(entry)
  entry.ftype == :file &&
  !entry.name.start_with?("__MACOSX/") &&
  entry.name.end_with?(".blend")
end
