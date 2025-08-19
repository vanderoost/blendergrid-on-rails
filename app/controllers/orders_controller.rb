class OrdersController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  skip_before_action :verify_authenticity_token, only: %i[ create ]

  def create
    if authenticated?
      @order = Current.user.orders.new order_params.merge(user: Current.user)
    else
      @order = Order.new order_params.merge(
        guest_email_address: session.dig(:guest_email_address)
      )
    end

    if @order.save
      redirect_to_safe_url @order.redirect_url
    else
      redirect_back fallback_location :projects, status: :unprocessable_content
    end
  end

  private
    def order_params
      params.expect(order: [ project_settings: {} ]).merge(redirect_urls)
    end

    def redirect_urls
      { success_url: projects_url, cancel_url: projects_url }
    end

    def redirect_to_safe_url(url)
      return redirect_to projects_path if url.blank?

      uri = URI.parse(url)
      if uri.host == "checkout.stripe.com"
        redirect_to url, allow_other_host: true
      else
        redirect_to projects_path
      end
    rescue URI::InvalidURIError
      redirect_to projects_path
    end
end
