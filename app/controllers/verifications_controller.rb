class VerificationsController < ApplicationController



def create
  current_user.sms_code =  1_000_000 + rand(10_000_000 - 1_000_000)
  current_user.save(validate: false)
  
  ###@user = current_user
  
  to = current_user.mobile
  
  ##if to[0] = "0"
  ##  to.sub!("0", '+44')
  ##end
	
	account_sid = "AC48ee31a74556a9b83eaf1f3779e731a6" # Your Account SID from www.twilio.com/console
	auth_token = "5f7cd10bce46d3246a263585182553fd"   # Your Auth Token from www.twilio.com/console
	###twilio_from = "+12345678901";
	twilio_from = "+15005550006";
	
  @twilio_client = Twilio::REST::Client.new account_sid, auth_token
  @twilio_client.account.sms.messages.create(
    :from => twilio_from,
    ###:to => "+#{to}",
	:to => '+923086737235',
    :body => "Your verification code is #{current_user.sms_code}."
  )



	DxMailer.sms_code(current_user).deliver
	
	
  
  redirect_to verifications_verify_path, :flash => { :success => "A verification code has been sent to your mobile. Please fill it in below." }
  return
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
  	render "verify"
	###render 'verifications/verify'
	###render :text => "Hello, World!"
  else	
    if current_user.sms_code == params[:sms_code]
      current_user.mobile_active = true
      current_user.sms_code = ''
      current_user.save(validate: false)
      redirect_to verifications_verify_path, :flash => { :success => "Thank you for verifying your mobile number." }
      return
    else
      redirect_to verifications_verify_path, :flash => { :errors => "Invalid verification code." }
      return
    end
	
  end
  
end

#############
end
