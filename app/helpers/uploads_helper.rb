module UploadsHelper
  def upload_workflow(new_upload: nil)
    render "uploads/workflow",
      new_upload: Upload.new,
      new_project_intake: Project::Intake.new,
      new_quote: Quote.new,
      new_order: Order.new,
      created_upload: last_upload,
      projects_by_status: recent_projects_by_status
  end

  private
    def recent_projects_by_status
      last_upload&.projects&.group_by(&:status)&.symbolize_keys || {}
    end

    def last_upload
      accessible_uploads.last
    end

    def accessible_uploads
      authenticated? ? Current.user.uploads : current_guest_uploads
    end

    def current_guest_uploads
      Upload.where(
        guest_email_address: session[:guest_email_address],
        guest_session_id: session.id.to_s,
        user_id: nil
      )
    end
end
