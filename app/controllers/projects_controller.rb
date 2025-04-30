class ProjectsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    projects = []
    Array(session[:project_source_uuids]).each do |project_source_uuid|
      project_source = ProjectSource.find_by(uuid: project_source_uuid)
      if not project_source or project_source.projects.empty?
        session[:project_source_uuids].delete(project_source_uuid)
        next
      end
      projects += project_source.projects
    end

    @projects = projects.sort_by(&:created_at).reverse
  end

  def show
    @project = Project.find(params[:id])

    s3 = Aws::S3::Resource.new # <-- resource, not Client
    bucket = s3.bucket(
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
