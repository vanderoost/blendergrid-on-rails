# Form object, take multiple Projects and turn it into an Order to be fulfilled
# On fulfillment, each Project gets a Render
class Order < ApplicationRecord
  include Trackable

  has_many :items, class_name: "Order::Item"
  belongs_to :user, optional: true

  attr_accessor :project_uuids, :success_url, :cancel_url, :redirect_url

  after_create :checkout

  # TODO: Add validations

  def fulfill
    Order::Fulfillment.new(self).handle
  end

  def price_cents
    items.sum(&:price_cents)
  end

  def partial_refund(permil)
    percent = permil.fdiv(10)
    refund_cents = price_cents * permil.fdiv(1000)
    puts "REFUNDING #{percent}% OF $#{refund_cents.fdiv(100)} ="\
      " $#{refund_cents.fdiv(100)}"

    # First refund in Render credit only.
    # After a timeout, and the credit hasn't been used, do a full refund.
  end

  private
    def checkout
      create_line_items
      @checkout = Order::Checkout.new(self)
      @checkout.start_checkout_session
    end

    def create_line_items
      # TODO: Optimize this. Right now, we're persisting the Order (to get an ID) then
      # we can create OrderItems associated with this Order (by ID) and then we use
      # those items to create the Stripe line items for the Stripe checkout session.
      # Instead, we should use a before_create callback on Order. We then create all
      # line items in memory first, use them for the Stripe checkout session, put the
      # Stripe related propertiies on the Order, and then persist the Order. Then
      # persist the OrderItems

      project_uuids.each do |uuid|
        project = Project.find_by(uuid: uuid)
        raise "Project '#{uuid}' not found" if project.nil?

        items.create(
          project: project,
          price_cents: project.price_cents,
          settings: {
            resolution_percentage: project.resolution_percentage,
            sampling_max_samples: project.sampling_max_samples,
            render_duration: project.render_duration,
          },
        )
      end

      raise "Order has no line items" if items.empty?
    end
end
