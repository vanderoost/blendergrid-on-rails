class ProjectSourcesController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    session[:project_source_uuid] = SecureRandom.uuid
  end

  # TODO: Defattify this
  def create
    @project_source = ProjectSource.new(uuid: session[:project_source_uuid])
    @project_source.attachments.attach(params[:attachments])

    # Allow creating projects when the user is not logged in. Email a magic link.
    if authenticated?
      @project_source.user = current_user

    else
      @project_source.user = User.where(email_address: params[:email_address])
        .first_or_create

      if @project_source.user
        session[:email_address] = @project_source.user.email_address
      end
    end

    @project_source.start_projects(params[:mainBlendFiles])
    @project_source.save!

    session[:project_source_ids] ||= []
    session[:project_source_ids] << @project_source.id

    # Rotate the Project Source ID
    session[:project_source_uuid] = SecureRandom.uuid

    redirect_to projects_path
  end
end
