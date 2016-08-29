class ProfileController < ApplicationController

  before_filter :authenticate_user!
  

  def index
 		@user = current_user
		render "profile"
  end
  
  def update
  		@user = current_user
		
  if request.post?
  	
	#if user mobile is changed then empty sms_code and set false active_mobile
	
	if params[:user][:mobile] != @user.mobile
	  @user.sms_code = ""
	  @user.mobile_active = false
	end
	
	##if @user.update_attributes params[:user]
	if @user.update_attributes (user_params)
      flash[:success] = 'The User is successfully updated!'
	  #render :text => "update"
	  #return
	  
      redirect_to profile_update_path
	  return
    else
        flash[:error] = @user.errors.full_messages
		#render :text => "error"
		#return
        redirect_to profile_update_path
		return
    end
	
  end
	
		###render :text => "out"
		render "update"
  end
  
  def picture
  	@user = current_user

	###if @user.update_attributes params[:user]
	###if @user.update_attribute params[:user][:avatar]
	
	if params[:user]
	
		if @user.update_attribute(:avatar, params[:user][:avatar])
			
		  @user.update_attribute(:linkedin_photo, '')
		  
		  flash[:success] = 'Profile picture uploaded!'
		  redirect_to profile_update_path
		  return
		
	    end
	end
	
	redirect_to profile_update_path
	
  end
  
  def preferences
  
  
  	@user = current_user
	
	if params[:UserSettings]
	
		settings = UserSettings.where(:user_id=>@user.id).first
		
		if settings
			settings.update_attributes(:sms => params[:UserSettings][:sms] , :email => params[:UserSettings][:email] ,  :outofnetwork => params[:UserSettings][:outofnetwork])
		else
			settings_new = UserSettings.new
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
	
	redirect_to profile_path
	
  end
  
  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :mobile, :provider, :uid, :sms_code, :mobile_active , :first_name , :last_name , :title , :firm_name , :address , :city , :state , :zip , :website , :photo , :avatar)
  end
 
#########
end
