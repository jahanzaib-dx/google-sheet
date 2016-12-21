class DxMailer < ActionMailer::Base

  default :from => "discreatelogix@gmail.com"
 
	def sms_code(user)
		@user = user
		mail(to: user.email, subject: "Mobile Verification - SMS Code")
	end
	
	def message_notification(user, message)
		@user = user
    @message = message
		mail(to: user.email, subject: "New Message")
	end
	
	def outgoing_reminder(comp_request)
    @comp_request = comp_request
	  mail(to: comp_request.received_by.email, subject: "Comp Sharing Request - Reminder")
	end
	
	def welcome_email(user)
		@user = user
		mail( :to => @user.email, :subject => "Welcome to MarketRex" )
  end

  def connection_invite(request)
    @connection_request = request
    mail(:to => request.receiver.email, :subject => "Connect Request at MarketRex")
	end

	def flag_comp_email(user,message)
		@user = user
		mail( :to => @user.email, :subject => message )
	end

	def white_glove_service_email(email,file)
		mail( :to => email, :subject => 'White glove service' )do |format|
      format.text do
        render :text => file
      end
    end
	end

end
