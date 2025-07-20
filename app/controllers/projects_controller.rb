class ProjectsController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    @projects = authenticated? ? Current.user.projects : Project.from_session(session)
  end
end
