module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :connection_id

    def connect
      self.connection_id = find_or_set_connection_id
    end

    private

    def find_or_set_connection_id
      cookies.encrypted[:connection_id] ||= SecureRandom.uuid
    end
  end
end
