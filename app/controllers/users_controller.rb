

class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
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
    @user = User.new(user_params)
    # only allow 'user' type accounts to be created via the website

#respond_to do |format|
#      if @user.save
#        format.html { redirect_to @user, notice: 'User was successfully created.' }
#        format.json { render :show, status: :created, location: @user }
#      else
#        format.html { render :new }
#        format.json { render json: @user.errors, status: :unprocessable_entity }
#      end
#    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    @user = set_user

    if params[:commit] == "transfer"
        @info = params[:user]
        puts @info[:from_account]
        puts @info[:to_account]
        @from_account = Account.find(@info[:from_account])
        @to_account = Account.find(@info[:to_account])
        @amount = params[:amount].to_f

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: @from_account.transfer(@to_account, @amount, @user)
                        }
            format.json { render :show, status: :ok, location: @user }
        end
    elsif params[:commit] == "calculate interest"
        @info = params[:user]
        puts @info[:from_account]
        @account = Account.find(@info[:from_account])

        respond_to do |format|
            format.html { redirect_to @user,
                          notice: @account.update_interest(@user)
                        }
            format.json { render :show, status: :ok, location: @user }
        end
    else
        respond_to do |format|
          if @user.update(user_params)
            format.html { redirect_to @user, notice: 'User was successfully updated.' }
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
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

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
