class Order::Fulfillment
  def initialize(order)
    @order = order
  end

  def handle
    @order.projects.each(&:start_rendering)
  end
end
