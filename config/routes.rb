Rails.application.routes.draw do
  root 'users#index'
  resource :chat, only: :create
  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]
  post 'users/bulk', to: 'users#bulk', as: :bulk_users
end
