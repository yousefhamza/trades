Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # Settings
  resource :settings, only: [ :show ] do
    delete :disconnect_slack, on: :member
  end

  # Web interface (session-based auth)
  resources :counters do
    member do
      post :increment
      post :share_to_slack
    end
  end

  # Slack endpoints
  post "slack/interactions", to: "slack_interactions#create"
  post "slack/events", to: "slack_events#create"

  # JSON API (token-based auth)
  namespace :api do
    resources :counters, only: [:index, :show, :create, :update, :destroy] do
      member do
        post :increment
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "counters#index"
end
