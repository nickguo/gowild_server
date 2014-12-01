class Api::SessionsController < Devise::SessionsController

  # POST /api/sign_in
  # Resets the authentication token each time! Won't allow you to login on two devices
  # at the same time (so does logout).
  def create
   puts 'ENTER WARDEN OKAY'
   authenticate_user!(:scope => resource_name, :store => false,
                        :recall => "#{controller_path}#failure")
   if not current_user.nil?
       render :status => 200,
              :json => { :success => true,
                         :info => "Logged in", 
                         :data => { :balance => current_user.savings_balance} }
   else
       render :json => {}.to_json, :success => false
   end

#puts 'WARDEN OKAY'
#   sign_in(resource_name, resource)
#   puts 'SIGN_IN OKAY'
 
#current_user.update authentication_token: nil
#   puts 'CURRENT_USER.UPDATE OKAY'

#   respond_to do |format|
#     format.json {
#       render :json => {
#    :user => current_user,
#         :status => :ok
#         :authentication_token => current_user.authentication_token
#       }
#     }
#   end
  end

  # DELETE /api/sign_out
  def destroy
 
   respond_to do |format|
     format.json {
       if current_user
         current_user.update authentication_token: nil
         signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
         render :json => {}.to_json, :status => :ok
       else
         render :json => {}.to_json, :status => :unprocessable_entity
       end
     }
   end
  end

end

