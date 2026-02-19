class OrderMailer < ApplicationMailer
  default reply_to: "support@blendergrid.com"

  def abandoned_cart(order)
    @order    = order
    @projects = order.projects

    if order.user.present?
      email_address  = order.user.email_address
      @session_token = order.user.generate_token_for(:session)
    else
      email_address  = order.guest_email_address
      @session_token = order.projects.first.upload
                            .generate_token_for(:session)
    end

    mail(
      to:      email_address,
      subject: "need some help with rendering?",
    )
  end
end
