class HomeController < ApplicationController
  def index
  end

  def upload
    project_source_id = SecureRandom.uuid
    Rails.logger.info "Using project_source_id: #{project_source_id}"
    session[:project_source_id] = project_source_id
  end
end
