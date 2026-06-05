require "net/http"
require "uri"
require "json"

namespace :subscribers do
  desc "Import the active subscriber list from Kit (ConvertKit) into Subscriber"
  task import_from_kit: :environment do
    api_key = Rails.application.credentials.dig(:convertkit, :api_key)
    abort "Missing credentials.convertkit.api_key" if api_key.blank?

    imported = 0
    after = nil

    loop do
      params = { status: "active", per_page: 1000 }
      params[:after] = after if after
      uri = URI("https://api.kit.com/v4/subscribers")
      uri.query = URI.encode_www_form(params)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request["X-Kit-Api-Key"] = api_key
      request["Accept"] = "application/json"

      response = http.request(request)
      unless response.code.to_i.between?(200, 299)
        abort "Kit API error #{response.code}: #{response.body}"
      end

      body = JSON.parse(response.body)
      body.fetch("subscribers", []).each do |sub|
        Subscriber.import_from_kit(
          email:         sub["email_address"],
          first_name:    sub["first_name"],
          subscribed_at: sub["created_at"],
        )
        imported += 1
      end

      pagination = body.fetch("pagination", {})
      break unless pagination["has_next_page"]
      after = pagination["end_cursor"]
    end

    puts "Imported #{imported} subscribers from Kit."
  end
end
