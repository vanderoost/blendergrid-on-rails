Rails.application.routes.draw do
  root "landing_pages#show" # Default landing page

  get "up" => "rails/health#show", as: :rails_health_check

  # TODO: Narrow the methods down to only the ones implemented in controllers

  resource :signups, path: "signup", only: %w[new create]
  resource :session

  resources :users
  resources :passwords, param: :token
  resources :email_address_verifications, param: :token
  resources :uploads, param: :uuid do
    resources :project_intakes
  end
  resources :quotes
  resources :orders
  resources :projects, param: :uuid

  # API
  namespace :api do
    namespace :v1 do
      resource :workflow_progress, only: %w[update]
      resources :workflows, param: :uuid
      resources :node_supplies, only: [] do
        patch "/", on: :collection, action: :update
      end
    end
  end

  # Webhooks
  namespace :webhooks do
    # TODO: Consider making it more RESTful (events/stripe, POST event)
    post "stripe", to: "stripe#handle"
  end

  # Articles
  get "learn/articles/:slug", to: redirect("articles/%{slug}")
  resources :articles, param: :slug

  # Landing pages
  get "start/:slug", to: redirect("%{slug}")
  get ":slug", to: "landing_pages#show", as: :landing_page

  # Catch-all route for any remaining paths (must be last)
  get "*path", to: "landing_pages#show"
end
