class Api::SessionsController < Devise::SessionsController

  # POST /api/sign_in
  # Resets the authentication token each time! Won't allow you to login on two devices
  # at the same time (so does logout).
  def create
    case params[:request]  
    when "login"
       if not current_user.nil?
           render :status => 200,
                  :json => { :success => true,
                             :info => "Logged in", 
                             :data => { :balance => current_user.savings_balance} }
       else
           render :json => {}.to_json, :success => false
       end
    when "update_balance"
       if not current_user.nil?
           User.transaction do
              @user = current_user
              puts "current user balance: ", @user.savings_balance
              savings_diff = params[:balance].to_f
              puts "amount to add: ", savings_diff
              @user.savings_balance= @user.savings_balance + savings_diff
              puts "current user balance: ", @user.savings_balance
              @user.save
           end
           render :json => {:success => true}
       else
           render :json => {:success => false}
       end
    else
       render :json => {:error => "INVALID ACTION: " + params[:action]}
    end
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

