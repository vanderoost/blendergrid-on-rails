Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # API
  namespace :api do
    namespace :v1 do
      resources :workflows, only: [ :update ]
    end
  end

  # Webhooks / events
  namespace :webhooks do
    post "stripe", to: "stripe#handle"
  end

  resource :session

  resources :passwords, param: :token
  resources :price_calculations, only: [ :create ]
  resources :renders, only: [ :create ]
  resources :uploads
  resources :projects
  resources :users, except: [ :new ]
  resources :stripe_checkout_sessions, only: [ :create ]

  get "signup", to: "users#new"

  root "home#index"
end
