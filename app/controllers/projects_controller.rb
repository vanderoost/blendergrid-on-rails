class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :destroy ]
  allow_unauthenticated_access # Allow guests to manage their projects

  def index
    projects = Project.where(project_source_id: session[:project_source_ids])
      .includes(:project_source)
      .order(created_at: :desc)

    @projects_by_stage = projects.group_by(&:stage)
  end

  def show
    # TODO: Make it work, then clean up this mess
    bucket = Aws::S3::Resource.new.bucket(
      Rails.application.credentials.dig(:swarm_engine, :bucket)
    )

    @sample_frame_urls = []
    bucket.objects(prefix: "projects/#{@project.uuid}/output/sample-frames")
      .limit(5)
      .each do |sample_frame|
        @sample_frame_urls << sample_frame.presigned_url(:get, expires_in: 3600)
      end
  end

  def destroy
    @product.destroy
    redirect_to products_path
  end

  private

  def set_project
    project = Project.find_by(uuid: params[:id])
    render status: :not_found unless is_authorized?(project)

    @project = project
  end

  def is_authorized?(project)
    if authenticated?
      current_user.id == project.user_id
    else
      session[:project_source_ids].include?(project.project_source_id)
    end
  end
end
