class VerificationsController < ApplicationController



def create
  current_user.sms_code =  1_000_000 + rand(10_000_000 - 1_000_000)
  current_user.save(validate: false)
  
  ###@user = current_user
  
  # to = current_user.mobile
  
  ##if to[0] = "0"
  ##  to.sub!("0", '+44')
  ##end
	
	account_sid = "ACb16471f5cccc3219bf472f33a80bddae"
	auth_token = "3852d8bf4dbeb958187f14c9b82cef3e"
	###twilio_from = "+12345678901"
	twilio_from = "+14438600704"
  twilio_to= current_user.mobile

  @twilio_client= Twilio::REST::Client.new account_sid, auth_token
    @twilio_client.account.sms.messages.create(
        :from => twilio_from,
        :to => twilio_to,
        :body => "Your verification code is #{current_user.sms_code}."
    )


	#DxMailer.sms_code(current_user).deliver
  
  redirect_to verifications_verify_path, :flash => { :success => "A verification code has been sent to your mobile. Please fill it in below." }
  return
end

def mobile_number

end

def verify
	
	if !current_user
		session[:previous_url] = verifications_verify_path		
        redirect_to new_user_session_path, :flash => { :error => "Please sign in to verify your mobile number!" }
		return
    end
	
	### RegistrationsHelper
	
  ###if(params.has_key?(:sms_code))
  if !params[:sms_code]
  # if !params[:sms_code]
  # 	render :action => :mobile_number
    if params[:mobile]
      current_user.mobile = params[:mobile]
      current_user.save
      render :action => :verify
    end
	###render 'verifications/verify'
	###render :text => "Hello, World!"
  else	
    if current_user.sms_code == params[:sms_code]
      current_user.mobile_active = true
      current_user.sms_code = ''
      current_user.save(validate: false)
      if session[:after_mobile_verfication_redirect]
        redirect_to session[:after_mobile_verfication_redirect], :flash => { :success => "Thank you for verifying your mobile number." }
      else
        redirect_to verifications_verify_path, :flash => { :success => "Thank you for verifying your mobile number." }
      end
      return
    else
      redirect_to verifications_verify_path, :flash => { :errors => "Invalid verification code." }
      return
    end
	
  end
  
end

#############
end
