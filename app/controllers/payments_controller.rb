class PaymentsController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    projects = [ @project ] # TODO: Support multiple projects
    stripe_session = Stripe::Checkout::Session.create(
      mode: "payment",
      customer_email: "suzanne@blender.org", # So it's prefilled (use nil if unknown)
      line_items: projects.map { |p| create_line_item_from_project p },
      metadata: { project_uuid: projects.first.uuid }, # TODO: Something else to identify a collection of projects
      success_url: project_url(@project, paid: true),
      cancel_url: project_url(@project)
    )

    redirect_to stripe_session.url, allow_other_host: true
  end

  private
    def create_line_item_from_project(project)
      {
        price_data: {
          currency: "usd",
          unit_amount: project.quote.price_cents,
          product_data: { name: project.main_blend_file }
        },
        quantity: 1
      }
    end
end
