class UploadsController < ApplicationController
  def new
    @upload = Upload.new(uuid: SecureRandom.uuid)
  end

  def create
    @upload = Upload.new(upload_params)
    if @upload.save
      redirect_to @upload
    else
      render :new
    end
  end

  def show
    @upload = Upload.find(params[:id])
  end

  private
    def upload_params
      params.require(:upload).permit(:source_file, :uuid)
    end
end
