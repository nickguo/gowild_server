Rails.application.routes.draw do
    devise_for :users, :controllers => {:registrations => "registrations"}

    namespace :api do
    #devise_for :users, :controllers => {:sessions => "api/sessions", :registrations => "api/registrations"}
        devise_scope :user do
            post '' => "sessions#create"
        end
    end

    # only have update, since other account views are not needed
    resources :accounts, :only => [:update]

    resources :users, :without => [:show]

    get 'accounts' => "users#accounts"
    get 'transfers' => "users#transfers"

#get 'accounts', to: 'users#accounts'
#    get 'transfers', to: 'users#transfers'


    # have the default of the site be user's index
    root 'users#index'
end
