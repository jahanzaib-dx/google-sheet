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

end
