class AccountsController < ApplicationController
    def index
        @user = User.find(params[:user_id])
        @accounts = @user.accounts
    end

    def update
        @account = set_account
        amount = params[:amount].to_f
        @account.update_balance(amount, current_user, "deposit")
        redirect_to(:back)
    end

    def new
        @user = User.find(params[:user_id])
        @account = @user.accounts.build
        
        # add custom fields to the account after initial creation
        @account.closed = false
        @account.owner = sprintf("%s %s", @user.first_name, @user.last_name)
        @account.save
    end

    def edit
        @user = User.find(params[:user_id])
        @account = @user.accounts.find(params[:id])
    end

    def create
        @user = User.find(params[:user_id])
        @account = Account.new(account_params)
    end

    def destroy
        @user = User.find(params[:user_id])
        @account = Account.find(params[:id])
        @account.destroy
    end

    def account_params
        params.require(:account).permit(:type, :balance, :user)
    end

    def set_account
        @account = Account.find(params[:id])
    end
end
