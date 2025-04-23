return if ENV["SECRET_KEY_BASE_DUMMY"].present? # Prevent the build from shitting itself

Rails.application.config.to_prepare do
  class ActiveStorage::DirectUploadsController
    def create
      project_source_id = session[:project_source_id]

      Rails.logger.info "Custom project_source_id: #{project_source_id}"

      blob = ActiveStorage::Blob.create_before_direct_upload_custom(
        **blob_args, project_source_id:
      )

      render json: direct_upload_json(blob)
    end
  end

  ActiveStorage::Blob.singleton_class.prepend(Module.new do
    def create_before_direct_upload_custom(
      filename:,
      byte_size:,
      checksum:,
      content_type: nil,
      metadata: nil,
      project_source_id: nil
    )
        # TODO: Maybe put this in config?
        key = "project-sources/#{project_source_id}/#{filename}"
        Rails.logger.info "Using custom Blob key: #{key}"

        create!(
          key: key,
          filename: filename,
          byte_size: byte_size,
          checksum: checksum,
          content_type: content_type,
          metadata: metadata
        )
    end
  end)
end
