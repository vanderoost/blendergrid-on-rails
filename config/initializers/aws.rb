require "aws-sdk-sns"

Aws.config.update(
  region:        Rails.application.credentials.dig(:aws, :default_region) || "us-east-1",
  credentials:   Aws::Credentials.new(
                   Rails.application.credentials.dig(:aws, :access_key_id),
                   Rails.application.credentials.dig(:aws, :secret_access_key)
                 ),
)
endpoint = Rails.application.credentials.dig(:aws, :endpoint)
Aws.config[:sns] = { endpoint: endpoint } if endpoint.present?
