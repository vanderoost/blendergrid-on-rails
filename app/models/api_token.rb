class ApiToken < ApplicationRecord
  attr_accessor :token

  before_create :generate_token_and_digest

  validates :name, presence: true

  def self.authenticate(token)
    return nil if token.blank?

    digest = Digest::SHA256.hexdigest(token)
    api_token = find_by(token_digest: digest)

    if api_token
      api_token.update_column(:last_used_at, Time.current)
    end

    api_token
  end

  private

    def generate_token_and_digest
      self.token = SecureRandom.base58(32)
      self.token_digest = Digest::SHA256.hexdigest(token)
    end
end
