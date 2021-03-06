class ProfileController < ApplicationController


  def update
		@user = (@role == 'admin') ? User.find(params[:id]) : current_user
		# @user = current_user

  if request.post?
  	
	#if user mobile is changed then empty sms_code and set false active_mobile

		if params[:user][:mobile] != @user.mobile
			@user.sms_code = ""
			@user.mobile_active = false
			redirect_to verifications_create_path
		end
	
		#if @user.update_attributes params[:user]
		if @user.update_attributes (user_params)
				flash[:success] = 'The User is successfully updated!'
			return
			else
					flash[:error] = @user.errors.full_messages
			return
		end
			redirect_to :controller => 'profile', :action => 'update', :id => @user.id
  end
	

  end
  
  def picture
		@user = (@role == 'admin') ? User.find(params[:id]) : current_user
		# @user = current_user

	###if @user.update_attributes params[:user]
	###if @user.update_attribute params[:user][:avatar]
	
	if params[:user]
	
		if @user.update_attribute(:avatar, params[:user][:avatar])

      @user.update_attribute(:linkedin_photo, '')

		  flash[:success] = 'Profile picture uploaded!'


			redirect_to profile_update_path(:id => @user.id)
		  return
		
	    end
	end

	redirect_to :controller => 'profile', :action => 'update', :id => @user.id
		# redirect_to profile_update_path
	
  end
  
  def preferences
  
  
  	@user = current_user
	
	if params[:UserSettings]
	
		settings = UserSetting.where(:user_id=>@user.id).first
		
		if settings
			settings.update_attributes(:sms => params[:UserSettings][:sms] , :email => params[:UserSettings][:email] ,  :outofnetwork => params[:UserSettings][:outofnetwork])
		else
			settings_new = UserSetting.new
			settings_new.user_id = @user.id
			#preferences_new.sms = true
			#preferences_new.email = true
			
			if !params[:UserSettings][:sms].blank?
				settings_new.sms = params[:UserSettings][:sms]
			end
			
			if !params[:UserSettings][:email].blank?
				settings_new.email = params[:UserSettings][:email]
			end
			
			if !params[:UserSettings][:outofnetwork].blank?
				settings_new.outofnetwork = params[:UserSettings][:outofnetwork]
			end
			
			settings_new.save(validate: false)
		end
	
		
	end
	
	##redirect_to profile_path
		redirect_to dashboard_path
	
  end
  
  def password

		@user = (@role == 'admin') ? User.find(params[:id]) : current_user
		# @user = current_user

	if params[:user]
		
		if params[:user][:password].length < 8 
			flash[:error] = 'Password should be minimum 8 character'
			err = true
		end
		
		if params[:user][:password] != params[:user][:password_confirmation]
			flash[:error] = 'Password and Confirm Password should match'
			err = true
		end
				
		if !err
			if @user.update_attribute(:password, params[:user][:password])
	
			  flash[:success] = 'Password updated successfully'
        if @role == 'admin'
        redirect_to users_path
        else
        redirect_to new_user_session_path
			  end
        return
			
			end
		end
	end
	
	##render password
	##redirect_to profile_password_path
	
  end

  def destroy
    if User.find(params[:id]).destroy
    redirect_to users_path
    end
  end
  
  
  private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :mobile, :provider, :uid, :sms_code, :mobile_active , :first_name , :last_name , :title , :firm_name , :address , :city , :state , :zip , :website , :photo , :avatar, :total_export_permissions)
    end
 
#########
end
