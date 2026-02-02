Rails.application.routes.draw do
  root "landing_pages#show" # Default landing page

  get "up" => "rails/health#show", as: :rails_health_check

  resource :signups, path: "signup", only: %w[new create]
  resource :session, only: %w[new create destroy]
  resources :email_subscriptions, only: %w[new create]

  resources :users, only: %w[show update]
  resources :passwords, param: :token, only: %w[new create edit update]
  resources :email_address_verifications, param: :token, only: %w[show]
  resources :uploads, param: :uuid, only: %w[index show new create] do
    resources :project_intakes, only: %w[create]
  end
  resources :quotes, only: %w[create]
  resources :orders, only: %w[create]
  resources :projects, param: :uuid, only: %w[index show update destroy] do
    resources :renders, only: %w[create destroy]
    resources :blender_scenes, only: %w[update]
    resources :duplicates, only: %w[create]
  end
  resources :payment_intents, only: %w[create]

  # Account settings etc.
  resource :account, only: %w[show] do
    resources :transactions, only: %w[index]
    resources :monthly_affiliate_stats, only: %w[index]
    resources :payout_methods, only: %w[create]
  end

  # API
  namespace :api do
    namespace :v1 do
      resource :workflow_progress, only: %w[update]
      resources :workflows, param: :uuid, only: %w[update]
      resources :node_supplies do
        patch "/", on: :collection, action: :update
      end
    end
  end

  # Webhooks
  namespace :webhooks do
    resource :stripe_events, only: %w[create]
  end

  # Static pages
  get "faq", to: "pages#faq", as: :faq
  get "pricing", to: "pages#pricing", as: :pricing
  get "support", to: "pages#support", as: :support
  get "policies", to: "pages#policies", as: :policies
  get "policies/:slug", to: "pages#policies", as: :policy, constraints: {
    slug: /terms|privacy|refund/,
  }

  # Articles
  get "learn/articles/:slug", to: redirect("articles/%{slug}")
  resources :articles, param: :slug, only: %w[index show]
  resources :authors, param: :slug, only: %w[show]

  # Sitemap
  get "/sitemap.xml", to: "sitemap#index", defaults: { format: "xml" }

  # Landing pages
  get "start/:slug", to: redirect("%{slug}")
  get ":slug", to: "landing_pages#show", as: :landing_page

  # Catch-all
  get "*path", to: "landing_pages#show"
end
