Rails.application.routes.draw do
  root "uploads#new"

  get "up" => "rails/health#show", as: :rails_health_check

  # TODO: Narrow the methods down to only the ones implemented in controllers

  resource :signups, path: "signup", only: %w[new create]
  # TODO: Think about making it `resources :sessions, path: "session"`
  resource :session

  # resource :signups, only: %w[new create]
  resources :users
  resources :passwords, param: :token
  resources :email_address_verifications, param: :token
  resources :uploads, param: :uuid do
    resources :project_intakes
  end
  resources :quotes
  resources :orders
  resources :projects, param: :uuid

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
