class Order::Checkout
  def initialize(order)
    @order = order
    @projects = []
  end

  def handle
    make_line_items
    start_stripe_session
  end

  private
    def make_line_items
      @order.project_settings.each do |uuid, settings|
        project = Project.find_by(uuid: uuid)
        next if project.nil?

        @order.items.create(project: project, render_settings: settings)
        @projects << project
      end
    end

    def start_stripe_session
      stripe_session = Stripe::Checkout::Session.create(
        mode: "payment",
        customer_email: "suzanne@blender.org", # So it's prefilled (use nil if unknown)
        line_items: @projects.map { |p| create_line_item_from_project p },
        metadata: { order_id: @order.id.to_s },
        success_url: @order.success_url,
        cancel_url: @order.cancel_url
      )
      @order.stripe_session_id = stripe_session.id
      @order.redirect_url = stripe_session.url
      @order.save
    end

    def create_line_item_from_project(project)
      {
        price_data: {
          currency: "usd",
          unit_amount: project.benchmark.price_cents,
          product_data: { name: project.blend_filepath }
        },
        quantity: 1
      }
    end
end
