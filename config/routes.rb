Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Accounts: real sessions replace the acting user selector.
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create], path: "sign_up", path_names: { new: "" }
  resources :passwords, param: :token, only: %i[new create edit update]
  resource :profile, only: %i[show edit update]

  # A listing is always created inside a property; once it exists it is addressed on its own.
  resources :properties do
    resources :listings, only: %i[new create]
    resources :reviews, only: :create
  end
  resources :listings, except: %i[new create] do
    member do
      patch :publish
      patch :withdraw
      patch :mark_rented
    end

    # Seekers apply from the listing page; the host answers them in the listing's inbox.
    resources :applications, only: :create
    resource :inbox, only: :show
  end
  resources :neighborhoods
  resources :amenities, except: :show
  resources :applications, only: %i[index show] do
    member do
      patch :withdraw
      patch :shortlist
      patch :reject
      patch :accept
    end

    resources :visits, only: :create
  end

  # A visit is proposed inside an application; once it exists it is addressed on its own.
  resources :visits, only: [] do
    member do
      patch :confirm
      patch :cancel
      patch :complete
      patch :reschedule
    end
  end
end
