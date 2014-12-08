class RegistrationsController < Devise::RegistrationsController
    def new
        super
        puts "entered custom new"
    end

    def create
        super
        # set account type to be 'user' since only users can be created externally
        @user.account_type = "user"
        @user.save
    end

    def update
        super
        puts "entered custom update"
    end

    private
        # Never trust parameters from the scary internet, only allow the white list through.
        def sign_up_params
          params.require(:user).permit(:first_name, :last_name, :address,
                                       :email, :password, :password_confirmation)#:sign_out)
        end
end
