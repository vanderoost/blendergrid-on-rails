class UploadsController < ApplicationController
  before_action :set_upload, only: :show

  def show
  end

  def new
    @upload = Upload.new
  end

  def create
    @upload = Upload.new(upload_params)
    if @upload.save
      persist_in_session @upload
      redirect_to @upload
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_upload
      @upload = Upload.find_by!(uuid: params[:uuid])
    end

    def upload_params
      params.require(:upload).permit(:source_file, :uuid)
    end

    def persist_in_session(upload)
      session[:upload_uuids] ||= []
      session[:upload_uuids] << upload.uuid
    end
end
