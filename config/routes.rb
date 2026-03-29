Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  
  devise_scope :admin do
    get 'admins/sign_in', to: 'devise/sessions#new', as: :new_admin_session
    get 'admins/sign_out', to: 'devise/sessions#destroy', as: :destroy_admin_session
  end

  namespace :admin do
    resources :attendances, only: %i[index create update]
    resource :recsports, only: %i[show update] do
      post :test_access
      post :sync_now
      post :browser_sync
      match :browser_sync, via: :options
      post :start_browser_sync
    end
  end

  resources :workout_checkins, only: [:create]

  resources :attendance_records do
    member do
      patch :toggle
    end
  end


  resources :attendances do
    collection do
      patch :toggle   # supports toggling by date/player in calendar
      post :toggle_workout_complete # for coach to check/uncheck workout completion
    end
    member do
      patch :toggle
    end
  end

  post 'toggle_coach', to: 'roles#enable_coach'
  delete 'toggle_coach', to: 'roles#disable_coach'

  root "attendances#index"
end
