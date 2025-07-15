require "aws-sdk-core"

if Rails.env.production?
  Aws.config.update(
    region: "us-east-1",
    credentials: Aws::Credentials.new(
      Rails.application.credentials.dig(:aws, :access_key_id),
      Rails.application.credentials.dig(:aws, :secret_access_key)
    )
  )
else
  Aws.config.update(
    region:      "us-east-1",
    credentials: Aws::Credentials.new("test", "test"),
    endpoint:    "http://localhost:4566",
  )
end
