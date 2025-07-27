module UploadStashable
  MAX_STASHED_UPLOADS = 32

  extend ActiveSupport::Concern

  private

  def stash_upload(uuid)
    uuids = session[:upload_uuids] || []
    uuids.delete_at(i) if i = uuids.index(uuid)
    uuids << uuid.to_s
    overflow = uuids.length - MAX_STASHED_UPLOADS
    uuids.shift(overflow) if overflow > 0
    session[:upload_uuids] = uuids
  end

  def claim_stashed_uploads(user)
    return if session[:upload_uuids].blank?

    Upload.from_session(session).update_all(user_id: user.id)
    session.delete(:upload_uuids)
  end
end
