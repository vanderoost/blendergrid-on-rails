class DirectUploadsController < ActiveStorage::DirectUploadsController
  def create
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      key: make_key(params.dig(:upload_uuid), params.dig(:blob, :filename)),
      filename: params.dig(:blob, :filename),
      byte_size: params.dig(:blob, :byte_size),
      checksum:  params.dig(:blob, :checksum),
      content_type: params.dig(:blob, :content_type)
    )

    render json: direct_upload_json(blob)
  end

  private
    def make_key(uuid, filename)
      key_prefix = Rails.configuration.swarm_engine[:key_prefix]
      "#{key_prefix}/#{uuid}/#{filename}"
    end
end
