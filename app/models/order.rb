# Form object, take multiple Projects and turn it into an Order to be fulfilled
# On fulfillment, each Project gets a Render
class Order < ApplicationRecord
  include Trackable

  has_many :items, class_name: "Order::Item"
  belongs_to :user, optional: true

  attr_accessor :project_settings, :success_url, :cancel_url, :redirect_url

  # TODO: Add validations

  def fulfill
    Order::Fulfillment.new(self).handle
  end

  def price_cents
    items.sum(&:price_cents)
  end

  def checkout
    create_line_items
    @checkout = Order::Checkout.new(self)
    @checkout.start_checkout_session
  end

  private
    def create_line_items
      # TODO: Optimize this. Right now, we're persisting the Order (to get an ID) then
      # we can create OrderItems associated with this Order (by ID) and then we use
      # those items to create the Stripe line items for the Stripe checkout session.
      # Instead, we should use a before_create callback on Order. We then create all
      # line items in memory first, use them for the Stripe checkout session, put the
      # Stripe related propertiies on the Order, and then persist the Order. Then
      # persist the OrderItems

      project_settings.each do |uuid, settings|
        project = Project.find_by(uuid: uuid)
        next if project.nil?

        settings = {
          render: { sampling: { max_samples: settings["cycles_samples"].to_i } },
        }

        items.create(
          project: project,
          price_cents: project.price_cents(override_settings: settings),
          settings: settings,
        )
      end

      raise "No line items" if items.empty?
    end
end
