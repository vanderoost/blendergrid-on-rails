class GuestConversionMailer < ApplicationMailer
  default reply_to: "support@blendergrid.com"

  def rendered_as_guest(email_address)
  end
end
