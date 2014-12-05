

class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :deposit]

  # GET /users
  # GET /users.json
  def index
    puts 'INDEX'
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    @user =  set_user

#if @user.update_attributes(params[:user])
=begin    if @user.update_attributes(user_params)
        redirect_to @user
    else
        render "user"
    end"""
=end

    checkings_diff = params[:checkings_diff]
    savings_diff = params[:savings_diff]
    if checkings_diff
        @user.checkings_balance = @user.checkings_balance ?
                                  @user.checkings_balance + checkings_diff.to_f
                                  : checkings_diff.to_f
    end
    if savings_diff
        @user.savings_balance = @user.savings_balance ?
                                @user.savings_balance + savings_diff.to_f
                                : savings_diff.to_f
    end

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
