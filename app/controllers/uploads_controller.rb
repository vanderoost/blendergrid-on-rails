class UploadsController < ApplicationController
  before_action :set_upload, only: :show

  def new
    @upload = Upload.new
  end

  def create
    @upload = Upload.new(upload_params)
    if @upload.save
      redirect_to @upload
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private
    def set_upload
      @upload = Upload.find_by!(uuid: params[:uuid])
    end

    def upload_params
      params.require(:upload).permit(:source_file, :uuid)
    end
end
