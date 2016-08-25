class ActivityLog < ActiveRecord::Base
 
  def self.activityLog(user,status="all")
	
	 ##alog = Activity.all
	 
	 if status == 'all'
	 
	 	alog = ActivityLog.joins("LEFT JOIN tenent_records ON tenent_records.id = activity_logs.comp_id").where("activity_logs.receiver_id = ? OR activity_logs.sender_id = ?",user.id,user.id).select("activity_logs .* , tenent_records .*")
		
	 elsif status == 'incoming'
	 	alog = ActivityLog.joins("LEFT JOIN tenent_records ON tenent_records.id = activity_logs.comp_id").where("activity_logs.receiver_id = ? ",user.id).select("activity_logs .* , tenent_records .*")
		
	 elsif status == 'outgoing'
	 	alog = ActivityLog.joins("LEFT JOIN tenent_records ON tenent_records.id = activity_logs.comp_id").where("activity_logs.sender_id = ? ",user.id).select("activity_logs .* , tenent_records .*")
		
	 end
	 
	 return alog
	
  end
	 
#####end of class#############
end
