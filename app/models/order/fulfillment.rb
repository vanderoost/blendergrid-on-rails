class Order::Fulfillment
  def initialize(order)
    @order = order
  end

  def handle
    @order.items.each do |item|
      project = item.project
      project.renders.create(cycles_samples: item.render_settings["cycles_samples"])
    end
  end
end
