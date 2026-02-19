class ApplicationMailer < ActionMailer::Base
  default from: "Blendergrid <info@blendergrid.com>"
  layout "mailer"

  after_action :record_email_send

  private

  def record_email_send
    return if message.to.blank?
    Email.create!(
      email_address: message.to.first,
      mailer_class:  self.class.name,
      action:        action_name,
    )
  end
end
