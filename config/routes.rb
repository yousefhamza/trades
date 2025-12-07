Rails.application.routes.draw do
  devise_for :users

  # Web interface (session-based auth)
  resources :counters do
    member do
      post :increment
      post :share_to_slack
    end
  end

  # Slack interactivity endpoint
  post "slack/interactions", to: "slack_interactions#create"

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
