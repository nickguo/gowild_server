class Api::SessionsController < Devise::SessionsController

    # POST /api/sign_in
    # primary route parser that will sanitize and determine which action
    # since it inherits from devise's sessions controller, has authentication
    def create
        # check if user information is valid
        if current_user.nil? 
            render :json => {:success => false,
                             :error => "INVALID USER"}
            return
        end

        # handle request
        case params[:request]  
            when "login"; login
            when "update_balance"; update_balance
            when "create_account"; create_account
            when "deposit"; deposit 
            else # action is invalid
                render :json => {:success => false,
                                 :error => "INVALID ACTION -> " + params[:request]}
        end
    end

    # definitions for lolgin

    # returns the user's information
    def login 
        render :json => { :success => true,
                          :info => { :accounts => current_user.accounts} }
    end

    def update_balance
        if not current_user.nil?
            savings_diff = params[:balance].to_f
            current_user.savings_balance= current_user.savings_balance + savings_diff
            current_user.save
            render :json => {:success => true}
        else
            render :json => {:success => false}
        end
    end

    def create_account
        @account = Account.new
        @account.balance = 0
        @account.account_type = "savings"
        @account.account_number = rand(1290000000 .. 1299999999)
        # loop to find a new account in case account id was already used
        while Account.find_by_account_number(@account.account_number)!= nil
            @account.account_number = rand(1290000000 .. 1299999999)
        end
        current_user.accounts.push @account
        current_user.save
        render :json => {:success => true}
    end

    def deposit
        @account_number = params[:account_number].to_i
        @amount = params[:amount].to_i
        @account = current_user.accounts.where(:account_number => @account_number).first
        puts "pre search"
        puts @account
        puts "post search"
        if not @account.nil?
            @account.balance += @amount
            @account.save
            render :json => {:success => true}
        else
            render :json => {:success => false}
        end
    end

end

