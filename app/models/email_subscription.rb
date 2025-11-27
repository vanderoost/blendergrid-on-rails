require "uri"
require "net/http"

class EmailSubscription
  include ActiveModel::Model
  include ActiveModel::Attributes
  include EmailValidatable

  attribute :email_address, :string

  validates :email_address, presence: true, length: { maximum: 255 }
  validates :email_address, format: EmailValidatable::VALID_EMAIL_REGEX

  def save
    create_kit_subscription if valid?
  end

  def model_name
    ActiveModel::Name.new(self, nil, self.class.name)
  end

  private
    def create_kit_subscription
      begin
        # TODO: Put this in a background job, also add to a form? Or keep track of the
        # subscripiton source at least.
        url = URI("https://api.kit.com/v4/subscribers")

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless Rails.env.production?

        request = Net::HTTP::Post.new(url)
        request["X-Kit-Api-Key"] = Rails.application.credentials.dig(
          :convertkit, :api_key
        )

        request["Content-Type"] = "application/json"
        request.body = {
          email_address: email_address,
        }.to_json

        response = http.request(request)

        if response.code.to_i >= 200 && response.code.to_i < 300
          true
        else
          errors.add(:base, "Unable to subscribe. Reason unknown..")
          false
        end
      rescue => e
        puts "ERROR: #{e.message}"
        errors.add(:base, "There was an error creating your subscription.")
        false
      end
    end
end
