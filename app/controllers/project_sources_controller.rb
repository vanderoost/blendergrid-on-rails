class ProjectSourcesController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    project_source_id = SecureRandom.uuid
    Rails.logger.info "Using project_source_id: #{project_source_id}"
    session[:project_source_id] = project_source_id
  end

  def create
    project_source_id = session[:project_source_id]
    @project_source = ProjectSource.new(uuid: project_source_id)
    @project_source.attachments.attach(params[:attachments])

    # Allow creating projects when the user is not logged in. Email a magic link.
    if authenticated?
      @project_source.user = current_user
    else
      @project_source.user = User.first_or_create!(email_address: params[:email])
    end

    projects_attributes = []
    params[:mainBlendFiles].each do |index|
      projects_attributes << {
        name: @project_source.attachments[index.to_i].blob.filename,
        uuid: SecureRandom.uuid
      }
    end
    @project_source.projects_attributes = projects_attributes
    session[:project_source_uuids] ||= []
    session[:project_source_uuids] << @project_source.uuid
    @project_source.save!

    redirect_to projects_path
  end
end
