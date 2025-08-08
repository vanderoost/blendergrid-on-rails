# Form object, take multiple Projects and turn it into an Order to be fulfilled
# On fulfillment, each Project gets a Render
class Order < ApplicationRecord
  has_many :items, class_name: "Order::Item"
  belongs_to :user, optional: true

  attr_accessor :project_settings, :success_url, :cancel_url, :redirect_url

  after_create :checkout

  def fulfill
    Order::Fulfillment.new(self).handle
  end

  private
    def checkout
      make_line_items
      @checkout = Order::Checkout.new(self)
      @checkout.handle
    end

    def make_line_items
      project_settings.each do |uuid, settings|
        project = Project.find_by(uuid: uuid)
        next if project.nil?

        project.settings_revisions.create(settings: { render: { sampling:
          { max_samples: settings["cycles_samples"].to_i }
        } })

        items.create(project: project, price_cents: project.price_cents)
      end
    end
end
