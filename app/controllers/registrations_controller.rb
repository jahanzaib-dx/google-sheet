class RegistrationsController < Devise::RegistrationsController

  def new
    unless session[:visited_plan]
      redirect_to subscription_plans_url
    else
      super
    end
  end

  def create
    super
  end

  def update
    super
  end


  private
  
    def sign_up_params
        params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :username, :mobile, :provider, :uid, :sms_code, :mobile_active , :first_name , :last_name , :title , :firm_name , :address , :city , :state , :zip , :website , :photo , :avatar)
      end
  
    def account_update_params
        params.require(:user).permit(:email, :password, :password_confirmation, :remember_me, :username, :mobile, :provider, :uid, :sms_code, :mobile_active , :first_name , :last_name , :title , :firm_name , :address , :city , :state , :zip , :website , :photo , :avatar)
      end

end