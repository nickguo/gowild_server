class Api::SessionsController < Devise::SessionsController

    # POST /api
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
            when "withdraw"; withdraw
            when "transfer"; transfer
            else # action is invalid
                render :json => {:success => false,
                                 :error => "invalid request " + params[:request]}
        end
    end

    # definitions for lolgin

    # returns the user's information
    def login 
        render :json => { :success => true,
                          :info => {:accounts => current_user.accounts.as_json}
                        }
    end

    def create_account
        @account_type = params[:account_type]
        render :json => {:success => current_user.create_account(@account_type) != 0}
    end

    def deposit
        @account_number = params[:account_number].to_i
        @amount = params[:amount].to_f
        @account = current_user.accounts.where(:account_number => @account_number).first
        if not @account.nil?
            @account.update_balance(@amount, current_user, "deposit")
            render :json => {:success => true}
        else
            render :json => {:success => false, :error => sprintf("Account %d not found for %s",
                                                                  @account_number, current_user.email)}
        end
    end

    def withdraw
        @account_number = params[:account_number].to_i
        if current_user.account_type == "user"
            @account = current_user.accounts.where(:account_number => @account_number).first
        else
            @account = Account.find_by_account_number(@account_number)
        end

        if @account.nil?
            render :json => {:success => false, :error => sprintf("Account %d not found for %s",
                                                                  @account_number, current_user.email)}
            return
        end

        @amount = params[:amount].to_f

        if @amount <= 0
            render :json => {:success => false, :error => sprintf("Withdraw must be greater than $0.00",
                                                                  @amount) }
            return
        end

        if @account.balance - @amount > 0
            @account.update_balance(-@amount, current_user, "withdraw")
            render :json => {:success => true}
        else
            render :json => {:success => false, :error => sprintf("Account %d has insufficient funds to withdraw $%.2f",@account_number, @amount)}
        end
    end

    def transfer
        @from_account = Account.find_by_account_number(params[:from_account].to_i)
        @to_account = Account.find_by_account_number(params[:to_account].to_i)
        @amount = params[:amount].to_f

        if @from_account.nil?
            render :json => {:success => false, :error => sprintf("Origin account %s not found",
                                                                  params[:from_account])}
            return
        end

        if @to_account.nil?
            render :json => {:success => false, :error => sprintf("Destination account %s not found",
                                                                  params[:to_account])}
            return
        end

        if current_user.account_type != "teller"
            if current_user != @from_account.user
                render :json => {:success => false,
                                 :error => sprintf("%s is not allowed to make transfers for account %d",
                                                   current_user.email, @from_account.account_number)
                                }
                return
            end
        end

        if @from_account == @to_account
            render :json => {:success => false, :error => sprintf("Account %s cannot transfer to itself",
                                                                   @from_account.account_number)
                            }
            return
        end

        if @amount <= 0
            render :json => {:success => false, :error => sprintf("Please enter a transfer of more than $0.00")
                            }
            return
        end

        if @from_account.balance >= @amount
            @from_account.update_balance(-@amount, current_user, sprintf("transfer to %d", @to_account.account_number))
            @to_account.update_balance(@amount, current_user, sprintf("transfer from %d", @from_account.account_number))
            render :json => {:success => true}
            return
        else
            render :json => {:success => false,
                             :error => sprintf("Transfer from %d failed. Please check for sufficient funds",
                                               @from_account.account_number)
                            } 
            return
        end
    end
end

