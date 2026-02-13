Rails.application.routes.draw do
  # --- 1. The Home Page ---
  root 'members#index'

  # --- 2. Resources ---
  # These allow you to Create, Read, Update, and Delete data
  resources :members
  resources :attendance_records
  resources :weekly_workouts

  # --- Health Check (Standard in Rails 8) ---
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :session, only: %i[new create destroy]

  namespace :admin do
    resources :attendances, only: %i[index create update]
    resource :recsports, only: %i[show update] do
      post :test_access
      post :sync_now
    end
  end

  resources :attendances, only: :index
  resources :workout_checkins, only: :create

  root "attendances#index"
end
