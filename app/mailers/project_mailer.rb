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
    if @project.user.present?
      email_address = @project.user.email_address
      @session_token = @project.user.generate_token_for(:session)
    elsif @project.upload.guest_email_address.present?
      email_address = @project.upload.guest_email_address
      @session_token = @project.upload.generate_token_for(:session)
    else
      return
    end

    mail(
      to: email_address,
      subject: "project '#{@project.blend_filepath}' is ready to render"
    )
  end

  def project_render_finished(project)
    @project = project
    @user = @project.user
    @session_token = @user.generate_token_for(:session)
    mail(
      to: @user.email_address,
      subject: "project '#{@project.blend_filepath}' has finished rendering"
    )
  end
end
