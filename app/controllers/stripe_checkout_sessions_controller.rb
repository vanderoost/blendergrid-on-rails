class StripeCheckoutSessionsController < ApplicationController
  allow_unauthenticated_access

  def create
    projects = Project.where(uuid: params[:project_uuids])

    Rails.logger.debug "Creating Stripe checkout session for #{projects.count} projects"

    line_items = projects.map do |project|
      {
        price_data: {
          currency: "usd",
          product_data: { name: "Render project: #{project.name}" },
          unit_amount: project.price
        },
        quantity: 1
      }
    end

    session = Stripe::Checkout::Session.create({
      line_items:,
      mode: "payment",
      ui_mode: "embedded",
      return_url: projects_url + "?session_id={CHECKOUT_SESSION_ID}"
      # TODO: Enable option to save credit card info
    })

    # TODO: Associate the Stripe Session with the Projects, so that when we get a
    # payment completed webhook event, we can start rendering the Projects
    projects.each do |project|
      if project.stripe_session_id.nil?
        project.update!(stripe_session_id: session.id)
      end
    end

    render json: { clientSecret: session.client_secret }
  end
end
