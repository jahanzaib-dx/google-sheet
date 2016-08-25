class ActivityLogsController < ApplicationController
  
  before_filter :authenticate_user!
  respond_to :html  

  def index  		
  		
		if params[:atype] == 'in'
			@user_activity = ActivityLog.activityLog(current_user,"incoming")
			
			@atype = 'in'
		
		elsif params[:atype] == 'out'
			@user_activity = ActivityLog.activityLog(current_user,"outgoing")
			
			@atype = 'out'
		else
			@user_activity = ActivityLog.activityLog(current_user,"all")
			
			@atype = 'log'
		end
	
	render "activity"
  end
  
  def update
  	if params[:astatus] && params[:aids]
		
		astatus = params[:astatus]
		
		status_array = ["Approve","Decline","Lock","Unlock","Partial"].include? astatus
		
		if status_array && params[:aids].length > 0
			
				params[:aids].each do |id|
					aLog = ActivityLog.find(id)
					aLog.update_attribute(:status, astatus)
				end		
		end
		
	end
	
	redirect_to activity_logs_path
  end
  
  def remind
  
  	if params[:receiverid]
		
		sender = current_user
		receiver = User.where("id=?",params[:receiverid]).first
		
		DxMailer.outgoing_reminder(sender,receiver).deliver
		
	end
	
	redirect_to activity_logs_path
  end
  
  def list  		
  		
		@user_activity = ActivityLog.all
		
	render "activity"
  end

end
