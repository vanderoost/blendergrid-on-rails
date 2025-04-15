class ProjectSourcesController < ApplicationController
  def create
    User.where(email: params[:email]).first_or_create

    # TODO: Capture projects (.blend file names)
    projects_attributes = [
      { name: "suzanne", uuid: SecureRandom.uuid },
      { name: "papaya", uuid: SecureRandom.uuid }
    ]

    project_source_id = session[:project_source_id]
    @project_source = ProjectSource.new(uuid: project_source_id, projects_attributes:)
    @project_source.attachments.attach(params[:attachments])
    @project_source.save!

    @project_source.attachments.each do |attached_file|
      Rails.logger.info "attached_file: #{attached_file.inspect}"
    end

    redirect_to projects_path
  end
end
