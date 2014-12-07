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

    resources :users, :only => [:update, :show, :index]

    # routes for the upper task bar
    get 'notice', :to => redirect("/notice.html.erb")
    get 'accounts' => "users#accounts"
    get 'transfers' => "users#transfers"
    get 'withdrawals' => "users#withdrawals"
    get 'deposits' => "users#deposits"
    get 'interests_and_penalties' => "users#interests_and_penalties"
    get 'create' => "users#create_account"

    # routes for errors controller
    get '/404' => 'errors#not_found'
    get '/422' => 'errors#server_error'
    get '/500' => 'errors#server_error'
    get '*path', :to => 'errors#not_found'

    # have the default of the site be user's index
    root 'users#index'
end
