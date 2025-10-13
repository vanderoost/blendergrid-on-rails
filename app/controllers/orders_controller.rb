class OrdersController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  skip_before_action :verify_authenticity_token, only: %i[ create ]

  def create
    @order = Order.new(order_params)

    if @order.save
      redirect_to_safe_url @order.redirect_url
    else
      redirect_back fallback_location: :projects, status: :unprocessable_content
    end
  end

  private
    def order_params
      resume_session # Manually resume session to set Current.user if logged in
      params.expect(order: [ project_uuids: [] ])
        .merge(redirect_urls)
        .merge(
          user: Current.user,
          guest_email_address: guest_email_address,
          guest_session_id: session[:guest_session_id]
        )
    end

    def redirect_urls
      { success_url: projects_url, cancel_url: projects_url }
    end

    def guest_email_address
      params.dig(:order, :guest_email_address) || session[:guest_email_address]
    end
end
