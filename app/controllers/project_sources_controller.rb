class ProjectSourcesController < ApplicationController
  # TODO: Too fat - Figure out how to refactor
  def create
    user = User.where(email: params[:email]).first_or_create

    project_source_id = session[:project_source_id]
    @project_source = ProjectSource.new(uuid: project_source_id)
    @project_source.attachments.attach(params[:attachments])

    projects_attributes = []
    params[:mainBlendFiles].each do |index|
      projects_attributes << {
        name: @project_source.attachments[index.to_i].blob.filename,
        uuid: SecureRandom.uuid,
        user_id: user.id
      }
    end
    @project_source.projects_attributes = projects_attributes
    @project_source.save!

    redirect_to projects_path
  end
end
