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

	def white_glove_service_email(email,file,encrypted_data)
		mail( :to => email, :subject => 'White glove service' )do |format|
      format.text do
        render :text => "Click on the link and get file "+file
        render :text => 'go to to the following link'
        render :text => encrypted_data
      end
    end
	end
	
	def comp_request_unlock(comp_request)    
    @comp_request = comp_request
    mail(to: comp_request.received_by.email, subject: "New Unlock Request")
  end
  
  def comp_request_approved(comp_request)
    @comp_request = comp_request
    mail(to: comp_request.initiated_by.email, subject: "Request Approved")
  end
  
  def comp_request_declined(comp_request)
    @comp_request = comp_request
    mail( :to => comp_request.initiated_by.email, :subject => "Request Declined" )
  end

end
