Rails.application.routes.draw do
  root "home#index"

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

  # Static pages
  resources :articles, param: :slug
  get "learn/articles/:slug", to: redirect("articles/%{slug}")

  # API
  namespace :api do
    namespace :v1 do
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
end
