module Uuidable
  extend ActiveSupport::Concern

  included do
    after_initialize :ensure_uuid

    def to_param
      uuid
    end
  end

  private
    def ensure_uuid
      self.uuid ||= SecureRandom.uuid
    end
end
