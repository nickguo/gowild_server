class RegistrationsController < Devise::RegistrationsController
    def new
        super
        puts "entered custom new"
    end

    def create
        @user = User.new(user_params)
        # only allow 'user' type accounts to be created via the website
        puts "REACHED HERE"
        @user.account_type = "user"

        respond_to do |format|
          if @user.save
            current_user = @user
            format.html { redirect_to @user, notice: 'User was successfully created.' }
            format.json { render :show, status: :created, location: @user }
          else
            format.html { render :new }
            format.json { render json: @user.errors, status: :unprocessable_entity }
          end
        end
    end

    def update
        super
        puts "entered custom update"
    end

    private
        # Never trust parameters from the scary internet, only allow the white list through.
        def user_params
          params.require(:user).permit(:email, :password, :password_confirmation, :sign_out)
        end
end
