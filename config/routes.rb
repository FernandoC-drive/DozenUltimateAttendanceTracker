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
end
