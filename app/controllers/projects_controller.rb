class ProjectsController < ApplicationController
  def index
    logger.info session[:upload_uuids].inspect
    @projects = Project.from_session(session)
  end
end
