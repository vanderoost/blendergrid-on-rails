class Order::Fulfillment
  def initialize(order)
    @order = order
  end

  def handle
    @order.items.each do |item|
      project = item.project
      project.start_rendering
    end
  end
end
