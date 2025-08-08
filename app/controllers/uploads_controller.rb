class UploadsController < ApplicationController
  include UploadStashable

  allow_unauthenticated_access only: %i[ index show new create ]
  before_action :set_upload, only: :show

  def index
    @uploads = accessible_uploads
  end

  def show
    @project_intake = Project::Intake.new
    @quote = Quote.new
    @order = Order.new
  end

  def new
    @upload = Upload.new
  end

  def create
    if authenticated?
      @upload = Current.user.uploads.new upload_params
    else
      session[:guest_email_address] = upload_params[:guest_email_address]
      @upload = Upload.new upload_params
    end

    if @upload.save
      redirect_back fallback_location: projects_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_upload
      # TODO: Only if it's accessible
      @upload = Upload.find_by!(uuid: params[:uuid])
    end

    def upload_params
      params.expect(
        upload: [ :uuid, :guest_email_address, files: [] ]
      ).merge(guest_session_id: session.id.to_s)
    end
end
