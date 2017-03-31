class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  def create
    @user = User.where('email = ? AND encrypted_password = "" ',params[:user][:email]).first
    if @user
      if params[:user][:password].length < 8
        flash[:error] = 'Password should be minimum 8 character'
        err = true
      end

      if params[:user][:password] != params[:user][:password_confirmation]
        flash[:error] = 'Password and Confirm Password should match'
        err = true
      end

      if !err
        @user.email = params[:user][:email]
        @user.first_name = params[:user][:first_name]
        @user.last_name = params[:user][:last_name]
        @user.password = params[:user][:password]
        @user.save(validate: false)
        sign_in @user, :bypass => true
        redirect_to root_path
      else
        redirect_to new_user_registration_path
      end
    else
      ###########email##########
      # @user = params[:user]
      # DxMailer.new_user_has_signed_up(@user).deliver
      ###########email##########
      super
    end

  end

  def update
    super
  end




  private
  
    def sign_up_params
        params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :mobile, :provider, :uid, :sms_code, :mobile_active , :first_name , :last_name , :title , :firm_name , :address , :city , :state , :zip , :website , :photo , :avatar)
      end
  
    def account_update_params
        params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :mobile, :provider, :uid, :sms_code, :mobile_active , :first_name , :last_name , :title , :firm_name , :address , :city , :state , :zip , :website , :photo , :avatar)
      end

end