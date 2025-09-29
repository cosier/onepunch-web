Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root route
  root "dashboard#index"

  # Authentication routes
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"
  get "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"

  # OAuth routes
  get "/auth/:provider/callback", to: "sessions#omniauth"

  # Dashboard
  get "/dashboard", to: "dashboard#index"

  # Timer routes
  post "/timer/start", to: "timer#start"
  post "/timer/stop/:id", to: "timer#stop"

  # Resource routes
  resources :time_entries
  resources :projects do
    member do
      patch :archive
    end
  end

  # For future expansion
  resources :clients, except: [:show]
end
