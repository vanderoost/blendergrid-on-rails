class OrdersController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  skip_before_action :verify_authenticity_token, only: %i[ create ]

  def create
    if authenticated?
      @order = Current.user.orders.new order_params
    else
      @order = Order.new guest_order_params
    end

    if @order.save
      redirect_to_safe_url @order.redirect_url
    else
      redirect_back fallback_location :projects, status: :unprocessable_content
    end
  end

  private
    def order_params
      params.expect(order: [ project_settings: {} ]).merge(
        user: Current.user, success_url: projects_url, cancel_url: projects_url
      )
    end

    def guest_order_params
      params.expect(order: [ project_settings: {}, redirect_url: projects_url ])
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
