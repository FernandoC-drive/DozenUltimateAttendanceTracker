Rails.application.routes.draw do

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
