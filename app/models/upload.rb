require "zip"

class Upload < ApplicationRecord
  include Uuidable
  include EmailValidatable

  belongs_to :user, optional: true
  has_many_attached :files
  has_many :projects

  after_create :analyze_zip_files

  validates :files, presence: true
  validates :guest_email_address, presence: true,
                                  format: EmailValidatable::VALID_EMAIL_REGEX,
                                  if: -> { user_id.blank? }
  validates :guest_session_id, presence: true, if: -> { user_id.blank? }

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
        next if zip_file.blob.byte_size > 1.gigabyte
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
