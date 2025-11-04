class DuplicatesController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access

  def create
    @duplicate = Project::Duplicate.new(project: @project)

    if @duplicate.save
      redirect_to :projects
    else
      render @project, status: :unprocessable_content
    end
  end
end
