class OrdersController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  skip_before_action :verify_authenticity_token, only: %i[ create ]

  def create
    order = Order.new(order_params)

    if order.save
      redirect_to order.redirect_url, allow_other_host: true
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
end
