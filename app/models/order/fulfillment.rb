class Order::Fulfillment
  def initialize(order)
    @order = order
  end

  def handle
    @order.items.each do |item|
      project = item.project
      project.renders.create
    end
  end
end
