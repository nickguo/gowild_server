class UsersController < ApplicationController
#  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = set_user
  end

  # GET /users/new
  def new
    @user = User.new
    @user.account_type = "user"
    @user.save
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    # only allow 'user' type accounts to be created via the website
    @user = User.new(user_params)
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    @user = set_user

    # check the parameter for 'commit' coming in and switch accordingly

    if params[:commit] == "transfer"
        # get the transfer info
        @info = params[:user]
        @from_account_id = @info[:from_account]
        @to_account_id = @info[:to_account]

        # setup for multiple routes to here in case to_account_id is provided differently
        if not @to_account_id
            @to_account_id = params[:to_account]
        end

        # perform basic sanitation and redirect upon error
        if @from_account_id == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select an account to transfer from"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        if @to_account_id  == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select an account to transfer to"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        # find the accounts
        @from_account = Account.find_by_id(@from_account_id)
        @to_account = Account.find_by_id(@to_account_id)

        # check if accounts exist
        if @to_account == nil
            @to_account = Account.where(account_number: @to_account_id, closed: false).first
        end

        if @to_account == nil
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: sprintf("Invalid account '%s' to transfer to", @to_account_id)
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end
        
        # transfer the amount
        @amount = params[:amount].to_f

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: @from_account.transfer(@to_account, @amount, @user)
                        }
            format.json { render :show, status: :ok, location: @user }
        end

    elsif params[:commit] == "calculate interest"
        # get account information and check that it's valid
        @info = params[:user]
        if @info[:from_account] == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select an account to calculate interests/penalties for"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        # calculate interest after sanitation
        @account = Account.find(@info[:from_account])

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: @account.update_interest_or_penalty(@user)
                        }
            format.json { render :show, status: :ok, location: @user }
        end

    elsif params[:commit] == "deposit"
        # get target account information and sanitize
        @info = params[:user]
        puts @info[:to_account]

        if @info[:to_account] == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select an account to deposit into"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        # deposit into the targeted account
        @to_account = Account.find(@info[:to_account])
        @amount = params[:amount].to_f

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: @to_account.deposit(@amount, @user)
                        }
            format.json { render :show, status: :ok, location: @user }
        end

    elsif params[:commit] == "withdraw"
        @info = params[:user]

        if @info[:from_account] == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select an account to withdraw from"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        @to_account = Account.find(@info[:from_account])
        @amount = params[:amount].to_f

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: @to_account.withdraw(@amount, @user)
                        }
            format.json { render :show, status: :ok, location: @user }
        end

    elsif params[:commit] == "create account" # for a bank acc, not for a user acc
        # get account information as given        
        @user_info = params[:user]
        @user_iden = @user_info[:from_account]
        @account_type = @user_info[:account_type]

        # sanitize
        if @user_iden == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select a user account to create an account for"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        if @account_type == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select an account type"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        # find the selected user and create an account
        @selected_user = User.find(@user_iden)

        @new_account_number = @selected_user.create_account(@account_type)

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: sprintf("%s account %d created for %s", @account_type, @new_account_number, @selected_user.email)
                        }
            format.json { render :show, status: :ok, location: @user }
        end

    elsif params[:commit] == "close account"
        # obtain information for account to close
        @user_info = params[:user]
        @account_iden = @user_info[:from_account]

        if @account_iden == ""
            respond_to do |format|
                format.html { redirect_to @user,
                              notice: "Please select an account to close"
                            }
                format.json { render :show, status: :ok, location: @user }
            end
            return
        end

        # find the account to be closed
        @selected_account = Account.find(@account_iden)

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: @selected_account.close_account(@user)
                        }
            format.json { render :show, status: :ok, location: @user }
        end

    else #no actions found
        respond_to do |format|
          if @user.update(user_params)
            format.html { redirect_to @user, notice: 'Unknown action given.' }
            format.json { render :show, status: :ok, location: @user }
          else
            format.html { render :edit }
            format.json { render json: @user.errors, status: :unprocessable_entity }
          end
        end
    end
  end


  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = set_user
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # Route actions to redirect to the different pages

  def accounts
    if current_user
      render "accounts"
    else
      render "public/not_signed_in"
    end
  end

  def close_account
    if current_user
      render "close_account"
    else
      render "public/not_signed_in"
    end
  end

  def transfers
    if current_user
      render "transfers"
    else
      render "public/not_signed_in"
    end
  end

  def withdrawals
    if current_user
      render "withdrawals"
    else
      render "public/not_signed_in"
    end
  end

  # teller only
  def deposits
    if current_user
      if current_user.account_type == "teller"
        render "deposits"
      else
        render "public/not_allowed"
      end
    else
      render "public/not_signed_in"
    end
  end
  
  # teller only
  def create_account
    if current_user
      if current_user.account_type == "teller"
        render "create_account"
      else
        render "public/not_allowed"
      end
    else
      render "public/not_signed_in"
    end
  end

  # teller only
  def interests_and_penalties
    if current_user
      if current_user.account_type == "teller"
        render "interests_and_penalties"
      else
        render "public/not_allowed"
      end
    else
      render "public/not_signed_in"
    end
  end

  # DO NOT CODE EXTERNAL FUNCTIONS UNDERNEATH THIS LINE-------------------------
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:username, :password, :savings_balance,
                                   :checkings_balance, :sign_out)
    end

end
