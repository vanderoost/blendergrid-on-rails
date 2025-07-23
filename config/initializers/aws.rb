require "aws-sdk-core"

credentials = Rails.application.credentials.dig(:aws)
return if credentials.nil?

Aws.config.update(
  region: "us-east-1",
  credentials: Aws::Credentials.new(
    credentials.dig(:access_key_id),
    credentials.dig(:secret_access_key)
  ),
  s3: { force_path_style: !!credentials.dig(:force_path_style) }
)

endpoint = credentials.dig(:endpoint)
if endpoint.present?
  Rails.logger.info "Using custom AWS endpoint: #{endpoint}"
  Aws.config[:endpoint] = endpoint
end
