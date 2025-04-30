require "aws-sdk-core"

Aws.config.update(
  region: Rails.application.credentials.dig(:aws, :default_region) || "us-east-1",
  credentials: Aws::Credentials.new(
    Rails.application.credentials.dig(:aws, :access_key_id),
    Rails.application.credentials.dig(:aws, :secret_access_key)
  ),
)

endpoint = Rails.application.credentials.dig(:aws, :endpoint)
if endpoint.present?
  Rails.logger.info "Using custom endpoint: #{endpoint}"
  Aws.config[:s3] = { endpoint: endpoint, force_path_style: true }
  Aws.config[:sns] = { endpoint: endpoint }
end
