class ProjectMailer < ApplicationMailer
  def project_created(project)
    @project = project
    @user = @project.user
    mail(
      to: @user.email_address,
      subject: "you created project '#{@project.blend_file}'"
    )
  end

  def project_benchmark_finished(project)
    @project = project
    @user = @project.user
    mail(
      to: @user.email_address,
      subject: "project '#{@project.blend_file}' is ready to render"
    )
  end

  def project_render_finished(project)
    @project = project
    @user = @project.user
    mail(
      to: @user.email_address,
      subject: "project '#{@project.blend_file}' has finished rendering"
    )
  end
end
