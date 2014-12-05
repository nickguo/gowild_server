Rails.application.routes.draw do
    devise_for :users

    namespace :api do
    #devise_for :users, :controllers => {:sessions => "api/sessions", :registrations => "api/registrations"}
    devise_scope :user do
    post '' => "sessions#create"
    end
    end

    resources :users

    # only have update, since other account views are not needed
    resources :accounts, :only => [:update]

    # have the default of the site be user's index
    root 'users#index'

end
