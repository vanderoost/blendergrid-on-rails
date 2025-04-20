class ProjectSourcesController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @big_color = true
    project_source_id = SecureRandom.uuid
    Rails.logger.info "Using project_source_id: #{project_source_id}"
    session[:project_source_id] = project_source_id
  end

  # TODO: Defattify this method
  def create
    @project_source = ProjectSource.new(uuid: session[:project_source_id])
    @project_source.attachments.attach(params[:attachments])

    # Allow creating projects when the user is not logged in. Email a magic link.
    if authenticated?
      @project_source.user = current_user
    else
      @project_source.user = User.first_or_create!(email_address: params[:email])
    end

    @project_source.start_projects(params[:mainBlendFiles])
    @project_source.save!

    session[:project_source_uuids] ||= []
    session[:project_source_uuids] << @project_source.uuid

    redirect_to projects_path
  end
end
