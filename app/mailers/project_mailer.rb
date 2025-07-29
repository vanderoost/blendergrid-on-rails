class ProjectMailer < ApplicationMailer
  def project_created(project)
    @project = project
    @user = @project.user
    email_address = @user.email_address || @user.guest_email_address
    raise "No email address for user #{user.inspect}" if email_address.blank?
    mail(
      to: email_address,
      subject: "you created project '#{@project.blend_filepath}'"
    )
  end

  def project_quote_finished(project)
    @project = project
    @user = @project.user
    email_address = @user.email_address || @user.guest_email_address
    raise "No email address for user #{user.inspect}" if email_address.blank?
    mail(
      to: email_address,
      subject: "project '#{@project.blend_filepath}' is ready to render"
    )
  end

  def project_render_finished(project)
    @project = project
    @user = @project.user
    email_address = @user.email_address || @user.guest_email_address
    raise "No email address for user #{user.inspect}" if email_address.blank?
    mail(
      to: email_address,
      subject: "project '#{@project.blend_filepath}' has finished rendering"
    )
  end
end
