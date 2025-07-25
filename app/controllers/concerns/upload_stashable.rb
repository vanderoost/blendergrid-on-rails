module UploadStashable
  extend ActiveSupport::Concern

  private

  def stash_upload(upload)
    session[:upload_uuids] ||= []
    session[:upload_uuids] << upload.uuid
    session[:upload_uuids].uniq!
  end

  def claim_stashed_uploads(user)
    return if session[:upload_uuids].blank?

    Upload.from_session(session).update_all(user_id: user.id)
    session.delete(:upload_uuids)
  end
end
