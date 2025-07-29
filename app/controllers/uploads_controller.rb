class UploadsController < ApplicationController
  include UploadStashable

  allow_unauthenticated_access only: %i[ index show new create ]
  before_action :set_user, only: :create
  before_action :set_upload, only: :show

  def index
    @uploads = Current.user&.uploads || []
  end

  def show
  end

  def new
    @upload = Upload.new
  end

  def create
    @upload = @user.uploads.new upload_params
    if @upload.save
      redirect_to @upload
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = Current.user
      unless @user
        @user = User.create!(params.expect(upload: [ :guest_email_address ]))
        logger.info "Starting a new guest session"
        start_new_session_for @user
      end
      logger.info "User: #{@user.inspect}"
    end

    def set_upload
      @upload = Upload.find_by!(uuid: params[:uuid])
    end

    def upload_params
      params.expect(upload: [ :uuid, files: [] ])
    end
end
