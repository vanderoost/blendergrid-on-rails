Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :uploads, param: :uuid
  resources :projects, param: :uuid

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # API
  namespace :api do
    namespace :v1 do
      resources :workflows, param: :uuid
    end
  end

  # Defines the root path route ("/")
  root "uploads#new"

  # Custom Active Storage Direct Uploads
  post "/rails/active_storage/direct_uploads", to: "direct_uploads#create"
end
