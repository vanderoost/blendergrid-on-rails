require "zip"

class Upload < ApplicationRecord
  EXTERNAL_ZIP_CHECK_THRESHOLD = Rails.env.production? ? 512.megabytes : 10.megabytes
  MIN_SALES_CENTS_FOR_WORKERS = 100_00

  include EmailValidatable
  include Trackable
  include Uuidable

  belongs_to :user, optional: true
  has_many_attached :files
  has_many :zip_checks, class_name: "Upload::ZipCheck"
  has_many :projects

  generates_token_for :session, expires_in: 2.days

  after_create :find_blend_files_in_zip_files
  after_create :maybe_request_workers_later

  validates :files, presence: true
  validates :guest_email_address, presence: true,
                                  format: EmailValidatable::VALID_EMAIL_REGEX,
                                  if: -> { user_id.blank? }
  validates :guest_session_id, presence: true, if: -> { user_id.blank? }

  def ongoing_zip_checks
    zip_checks.select &:ongoing?
  end

  def blend_filepaths
    blend_files.map(&:filename).map(&:to_s) +
    zip_files.flat_map { |zf| zf.metadata["blend_filepaths"] || [] }
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
      next unless zip_file.filename.to_s == zip_check.zip_filename
        zip_file.metadata[:blend_filepaths] = zip_check.zip_contents.select {
          |path| path.end_with?(".blend")
        }
        zip_file.save

        maybe_create_project
      return
    end
    raise "No zip file found in Upload #{id} for #{zip_check.zip_filename}"
  end

  def maybe_request_workers
    return unless (user&.sales_cents || 0) > MIN_SALES_CENTS_FOR_WORKERS
    puts "Requesting workers because #{user&.email_address} created an Upload"
    SwarmEngine.new.ensure_workers
  end

  private
    def find_blend_files_in_zip_files
      zip_files.each do |zip_file|
        if zip_file.byte_size > EXTERNAL_ZIP_CHECK_THRESHOLD
          external_zip_check zip_file
        else
          internal_zip_check zip_file
        end
      end

      maybe_create_project
    end

    def internal_zip_check(zip_file)
      blend_entries = Zip::File.open_buffer(zip_file.download)
        .select { |entry| blend_entry? entry }
      zip_file.metadata[:blend_filepaths] = blend_entries.map(&:name)
      zip_file.save
    end

    def external_zip_check(zip_file)
      zip_checks.create(zip_filename: zip_file.filename.to_s)
    end

    def maybe_create_project
      if blend_filepaths.one? && ongoing_zip_checks.empty?
        project = projects.create!(blend_filepath: blend_filepaths.first)
        raise "Project could not be created" unless project.persisted?
      end
    end

    def maybe_request_workers_later
      MaybeRequestWorkersJob.perform_later(self)
    end
end

def blend_entry?(entry)
  entry.ftype == :file &&
  !entry.name.start_with?("__MACOSX/") &&
  entry.name.end_with?(".blend")
end
