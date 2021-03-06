class DxMailer < ActionMailer::Base

helper :comp

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
    mail(to: comp_request.received_by.email, subject: "New Unlock Request - Reminder")
	end
	
	def welcome_email(user)
		@user = user
		mail( :to => @user.email, :subject => "Welcome to MarketRex" )
	end
###########email##########
	# def new_user_has_signed_up(user)
	# 	@user = user
	# 	mail( :to => ['mnaumimirza@yahoo.com', 'mnaumimirza@hotmail.com'], :subject => "#{@user[:first_name]} #{@user[:last_name]} has signed up to Rexforce for first time." )
	# end
###########email##########

  def connection_invite(request)
		headers({'X-No-Spam' => 'True'})
    @connection_request = request
    mail(:to => request.receiver.email, :from => request.sender.email, :subject => "New Connection Request via MarketRex")
	end

	def connection_request_approved_email(request)
		headers({'X-No-Spam' => 'True'})
		@connection_request = request
		mail(:to => request.sender.email, :from => request.receiver.email , :subject => "New Connection #{request.receiver.first_name} #{request.receiver.last_name} ")

	end

	def flag_comp_email(user,message)
		@user = user
		@message = message
		mail( :to => @user.email, :subject => 'Flagged Comp' )
	end

	def white_glove_service_email(email,file,encrypted_data,is_geo_coded)
		@file = file
		@encrypted_data = encrypted_data
		@is_geo_coded = is_geo_coded
		mail( :to => email, :subject => 'White glove service request' )
	end
	def white_glove_service_completed_email(email,redirect_link)
		@redirect = redirect_link
		 mail( :to => email, :subject => 'White glove service request' )
	end
	
	def comp_request_unlock(comp_request)    
    @comp_request = comp_request
    mail(to: comp_request.received_by.email, subject: "New Unlock Request")
  end

	def searchable_new_comps(request)
		@connection_request =request
		mail(:to => request.connected_to.email, :from => request.user.email, :subject => "Congragulations! New Comps")

	end

	def searchable_sale_comps(request)
		@connection_request =request
		mail(:to => request.connected_to.email, :from => request.user.email, :subject => "Congragulations! New Comps")

	end

  def comp_request_approved(comp_request,email_comp_id=0)
    @comp_request = comp_request
    @email_comp_id = email_comp_id
    mail(to: comp_request.initiated_by.email, subject: "Request Approved")
  end
  
  def comp_request_declined(comp_request)
    @comp_request = comp_request
    mail( :to => comp_request.initiated_by.email, :subject => "Request Declined" )
  end
  
  def comp_request_approved_update(user,shared,email_comp_id=0)
    @shared = shared
    @user = user
    @email_comp_id = email_comp_id
    mail(to: shared.user.email, subject: "Request Approved")
  end
  
  def comp_request_declined_update(user,shared)
    @shared = shared
    @user = user
    mail( :to => shared.user.email, :subject => "Request Declined" )
  end

end
