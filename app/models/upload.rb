require "zip"

class Upload < ApplicationRecord
  BIG_FILE_SIZE = 512.megabytes

  include EmailValidatable
  include Trackable
  include Uuidable

  belongs_to :user, optional: true
  has_many_attached :files
  has_many :zip_checks, class_name: "Upload::ZipCheck"
  has_many :projects

  after_create :find_blend_filepaths

  validates :files, presence: true
  validates :guest_email_address, presence: true,
                                  format: EmailValidatable::VALID_EMAIL_REGEX,
                                  if: -> { user_id.blank? }
  validates :guest_session_id, presence: true, if: -> { user_id.blank? }

  def all_blend_filepaths
    blend_files.map(&:filename).map(&:to_s) +
    zip_files.map(&:metadata).flat_map { |m| m["blend_filepaths"] }
  end

  def blend_files
    files.select { |f| f.filename.extension == "blend" }
  end

  def zip_files
    files.select { |f| f.filename.extension == "zip" }
  end

  # TODO: Refactor this, super ugly
  def zip_check_done(zip_check)
    zip_files.each do |zip_file|
      next unless zip_file.filename.to_s == zip_check.zip_file
        zip_file.metadata[:blend_filepaths] = zip_check.zip_contents.select {
          |path| path.end_with?(".blend")
        }
        zip_file.save
      return
    end
    raise "No zip file found in Upload #{id} for #{zip_check.zip_file}"
  end

  private
    def find_blend_filepaths
      if zip_files.any?
        find_blend_files_in_zip_files
      elsif blend_files.one?
        projects.create(blend_filepath: blend_files.first.filename.to_s)
      end
    end

    def find_blend_files_in_zip_files
      zip_files.each do |zip_file|
        if zip_file.byte_size < BIG_FILE_SIZE
          internal_zip_check zip_file
        else
          external_zip_check zip_file
        end
      end
    end

    def internal_zip_check(zip_file)
      blend_entries = Zip::File.open_buffer(zip_file.download)
        .select { |entry| is_blend_entry? entry }
      zip_file.metadata[:blend_filepaths] = blend_entries.map(&:name)
      zip_file.save
    end

    def external_zip_check(zip_file)
      zip_checks.create(zip_file: zip_file.filename.to_s)
    end
end

def is_blend_entry?(entry)
  entry.ftype == :file &&
  !entry.name.start_with?("__MACOSX/") &&
  entry.name.end_with?(".blend")
end
