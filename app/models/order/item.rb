class Order::Item < ApplicationRecord
  belongs_to :order
  belongs_to :project

  def refund(promile = 1000)
    # TODO
  end
end
