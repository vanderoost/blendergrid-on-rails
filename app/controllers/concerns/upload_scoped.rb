module UploadScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_upload
  end

  private
    def set_upload
      @upload = Upload.find_by(uuid: params[:upload_uuid])
    end
end
