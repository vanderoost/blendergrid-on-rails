module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      # Original Rails 8 way:
      # set_current_user || reject_unauthorized_connection

      # New way, let everytyhing through:
      set_current_user

      # TODO: Do a `reject unless current_user` for certain channels we want to protect
    end

      def set_current_user
        if session = Session.find_by(id: cookies.signed[:session_id])
          self.current_user = session.user
        end
      end
  end
end
