class UploadsController < ApplicationController
  include UploadStashable

  allow_unauthenticated_access only: %i[ index show new create ]
  before_action :set_upload, only: :show

  def index
    @uploads = authenticated? ? Current.user.uploads : Upload.from_session(session)
  end

  def show
  end

  def new
    @upload = Upload.new
  end

  def create
    scope = authenticated? ? Current.user.uploads : Upload
    @upload = scope.new(upload_params)

    if @upload.save
      stash_upload @upload.uuid
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
      params.expect(upload: [ :uuid, files: [] ])
    end
end
