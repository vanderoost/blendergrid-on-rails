class UploadsController < ApplicationController
  include UploadStashable

  allow_unauthenticated_access only: %i[ index show new create ]
  before_action :set_upload, only: :show

  def index
    @uploads = accessible_uploads
  end

  def show
  end

  def new
    @upload = Upload.new
  end

  def create
    session[:guest_email_address] = upload_params[:guest_email_address]
    @upload = Upload.new(upload_params)
    if @upload.save
      redirect_to @upload
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
