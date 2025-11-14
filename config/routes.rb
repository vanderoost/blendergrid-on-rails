Rails.application.routes.draw do
  root "landing_pages#show" # Default landing page

  get "up" => "rails/health#show", as: :rails_health_check

  resource :signups, path: "signup", only: %w[new create]
  resource :session, only: %w[new create destroy]

  resources :users, only: %w[show]
  resources :passwords, param: :token, only: %w[new create edit update]
  resources :email_address_verifications, param: :token, only: %w[show]
  resources :uploads, param: :uuid, only: %w[index show new create] do
    resources :project_intakes, only: %w[create]
  end
  resources :quotes, only: %w[create]
  resources :orders, only: %w[create]
  resources :projects, param: :uuid, only: %w[index show update destroy] do
    resources :renders
    resources :blender_scenes
    resources :duplicates
  end
  resources :payment_intents, only: %w[create]

  # Account settings etc.
  resource :account, only: %w[show]

  # API
  namespace :api do
    namespace :v1 do
      resource :workflow_progress, only: %w[update]
      resources :workflows, param: :uuid
      resources :node_supplies do
        patch "/", on: :collection, action: :update
      end
    end
  end

  # Webhooks
  namespace :webhooks do
    # TODO: Consider making it more RESTful (events/stripe, POST event)
    post "stripe", to: "stripe#handle"
  end

  # Static pages
  get "pricing", to: "pages#pricing"
  get "policies", to: "pages#policies"
  get "policies/:slug", to: "pages#policies"

  # Articles
  get "learn/articles/:slug", to: redirect("articles/%{slug}")
  resources :articles, param: :slug

  # Landing pages
  get "start/:slug", to: redirect("%{slug}")
  get ":slug", to: "landing_pages#show", as: :landing_page

  # Catch-all
  get "*path", to: "landing_pages#show"
end
