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
    resource :render
  end

  namespace :api do
    namespace :v1 do
      resources :workflows, param: :uuid
      resources :node_supplies, only: [] do
        patch "/", on: :collection, action: :update
      end
    end
  end
end
