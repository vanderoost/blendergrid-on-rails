Rails.application.routes.draw do
  root "uploads#new"

  get "signup" => "users#new"
  get "up" => "rails/health#show", as: :rails_health_check
  post "rails/active_storage/direct_uploads", to: "direct_uploads#create"

  # TODO: Narrow the methods down to only the ones implemented in controllers

  resources :users
  resource :session
  resources :passwords, param: :token
  resources :uploads, param: :uuid
  resources :projects, param: :uuid do
    resource :price_calculation

    # TODO: Think of a better name than 'Payments'
    # TODO: For multi-project support, this should move somewhere else
    resources :payments, only: :create
  end

  namespace :api do
    namespace :v1 do
      resources :workflows, param: :uuid
      resources :node_supplies, only: [] do
        patch "/", on: :collection, action: :update
      end
    end
  end

  namespace :webhooks do
    post "stripe", to: "stripe#handle"
  end
end
