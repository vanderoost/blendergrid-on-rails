class UploadsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    session[:upload_uuid] = SecureRandom.uuid
  end

  # TODO: Defattify this
  def create
    @upload = Upload.new(uuid: session[:upload_uuid])
    @upload.attachments.attach(params[:attachments])

    # Allow creating projects when the user is not logged in. Email a magic link.
    if authenticated?
      @upload.user = current_user

    else
      @upload.user = User.where(email: params[:email])
        .first_or_create

      if @upload.user
        session[:email] = @upload.user.email
      end
    end

    @upload.start_projects(params[:mainBlendFiles])
    @upload.save!

    session[:upload_ids] ||= []
    session[:upload_ids] << @upload.id

    # Rotate the Upload UUID
    session[:upload_uuid] = SecureRandom.uuid

    if params[:mainBlendFiles].length > 1
      flash[:notice] = "Created #{params[:mainBlendFiles].length} projects!"
    else
      flash[:notice] = "Created a project!"
    end

    redirect_to projects_path
  end
end
