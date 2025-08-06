class Order < ApplicationRecord
  has_many :items, class_name: "Order::Item"

  attr_accessor :project_settings, :success_url, :cancel_url, :redirect_url

  after_create :checkout

  def fulfill
    Order::Fulfillment.new(self).handle
  end

  private
    def checkout
      @checkout = Order::Checkout.new(self)
      @checkout.handle
    end
end
