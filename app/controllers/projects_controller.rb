class ProjectsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    projects = Project.where(project_source_id: session[:project_source_ids])
      .includes(:project_source)
      .order(created_at: :desc)

    @projects_by_stage = projects.group_by(&:stage)
  end

  def show
    @project = Project.find(params[:id])

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
end
