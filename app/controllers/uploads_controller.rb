class UploadsController < ApplicationController
  include UploadStashable

  allow_unauthenticated_access
  before_action :set_upload, only: :show

  def show
  end

  def new
    @upload = Upload.new
  end

  def create
    scope = authenticated? ? Current.user.uploads : Upload
    @upload = scope.new(upload_params)

    if @upload.save
      stash_upload @upload
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
      # params.require(:upload).permit(:source_file, :uuid)
      params.expect(upload: [ :source_file, :uuid ])
    end
end
