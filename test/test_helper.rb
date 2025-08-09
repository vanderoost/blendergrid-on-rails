ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Stub AWS services in tests
require "aws-sdk-sns"
Aws.config[:stub_responses] = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    def sign_in_as(user)
      Current.session = user.sessions.create!

      ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
        cookie_jar.signed[:session_id] = Current.session.id
        cookies[:session_id] = cookie_jar[:session_id]
      end
    end

    def root_referrer_header
      { "HTTP_REFERER" => root_url }
    end
  end
end
