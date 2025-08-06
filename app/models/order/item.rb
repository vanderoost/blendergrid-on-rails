class Order::Item < ApplicationRecord
  belongs_to :order
  belongs_to :project
end
