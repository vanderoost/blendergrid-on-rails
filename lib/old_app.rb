class OldApp < ActiveRecord::Base
  self.abstract_class = true

  mysql_config = {
    adapter: "mysql2",
    host: Rails.application.credentials.dig(:old_database, :host),
    username: Rails.application.credentials.dig(:old_database, :username),
    password: Rails.application.credentials.dig(:old_database, :password),
    database: Rails.application.credentials.dig(:old_database, :name),
  }
  establish_connection(mysql_config)

  # Don't write to the old database!
  def readonly?
    true
  end
end

# class OldApp::Article < OldApp
#   self.table_name = "articles"
#   belongs_to :user
# end

class OldApp::User < OldApp
  self.table_name = "users"

  def name
    if firstname.present? && lastname.present?
      "#{firstname} #{lastname}"
    elsif firstname.present?
      firstname
    end
  end
end

class OldApp::LandingPage < OldApp
end

class OldApp::Article < OldApp
  belongs_to :team_member
  delegate :user, to: :team_member
end

class OldApp::TeamMember < OldApp
  belongs_to :user
end

class OldApp::ProjectSource < OldApp
  self.table_name = "project_sources"

  self.inheritance_column = :_type_disabled
end
