class DxMailer < ActionMailer::Base
default :from => "discreatelogix@gmail.com"
 
	def sms_code(user)
		###mail(:to => user.email, :subject => "SMS Code")
		
		mail(to: user.email, subject: "SMS Code") do |format|
		  format.html {
			render locals: { sms_code_no: user.sms_code }
		  }
		end
	end
	
	def message_notification(user,message)
		###mail(:to => user.email, :subject => "SMS Code")
		
		mail(to: user.email, subject: "New Message") do |format|
		  format.html {
			render locals: { user: user, message: message }
		  }
		end
	end
	
	def outgoing_reminder(sender,receiver)	
		
		@settings = UserSettings.where("user_id = ?",receiver.id)
		
			if @settings && @settings.email
				mail(to: receiver.email, subject: "Reminder") do |format|
				  format.html {
					render locals: { sender: sender, receiver: receiver }
				  }
			end
		end
	end
	
	def welcome_email(user)
		
		mail(to: user.email, subject: "Welcome to MarketRex") do |format|
		  format.html {
			render locals: { user: user }
		  }
		end
	end
	##---------------
end
