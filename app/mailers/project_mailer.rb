class ProjectMailer < ApplicationMailer
  default to:       -> { @user.email_address },
          reply_to: -> { "support@blendergrid.com" }

  def project_created(project)
    @project = project
    @user = @project.user
    mail(
      to: @user.email_address,
      subject: "you created project '#{@project.blend_filepath}'"
    )
  end

  def project_benchmark_finished(project)
    @project = project
    email_address = get_email_address(@project)
    @session_token = get_session_token(@project)

    return unless email_address.present? and @session_token.present?

    mail(
      to: email_address,
      subject: "project '#{@project.blend_filepath}' is ready to render"
    )
  end

  def project_render_finished(project)
    @project = project
    email_address = get_email_address(@project)
    @session_token = get_session_token(@project)

    return unless email_address.present? and @session_token.present?

    mail(
      to: email_address,
      subject: "project '#{@project.blend_filepath}' has finished rendering"
    )
  end

  private
    def get_email_address(project)
      if project.user.present?
        project.user.email_address
      elsif project.upload.guest_email_address.present?
        project.upload.guest_email_address
      end
    end

    def get_session_token(project)
      if project.user.present?
        project.user.generate_token_for(:session)
      elsif project.upload.guest_email_address.present?
        project.upload.generate_token_for(:session)
      end
    end
end
