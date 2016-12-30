class ActivityLogsController < ApplicationController

  before_filter :authenticate_user!

  def index
    
    if !params[:comp_type].blank?
      ##@activity_logs = ActivityLog.all_activities_with_type(current_user.id,params[:comp_type])
      activity_logs = ActivityLog.all_activities_with_type(current_user.id,params[:comp_type])
    else
      ##@activity_logs = ActivityLog.all_activities_of_user(current_user.id)
      activity_logs = ActivityLog.all_activities_of_user(current_user.id)
    end
    
    ##@activity_logs = []
    @activity_logs = activity_logs.each do |activity|
      unlockFields = SharedComp.getUnlockData activity
      
      lockData activity, unlockFields 
      
      
      
      # if unlockFields.include? "company"
        # activity.tenant_record.company = activity.tenant_record.company
      # else
        # activity.tenant_record.company = 'Lock'
      # end
#       
      # if unlockFields.include? "company"
        # activity.tenant_record.company = activity.tenant_record.company
      # else
        # activity.tenant_record.company = 'Lock'
      # end
      # p unlockFields
      # .include?
      ##activity.tenant_record.company = 'Lock'
    end
    ##@activity_logs = ActivityLog.all_activities_with_type(current_user.id)
  end
  
  private
  def lockData activity, unlockFields
    
    #activity_comp = if 
    if activity.comptype == 'lease'
      activity_comp = activity.tenant_record
      
      activity_comp.company = if unlockFields.include?"company" then activity_comp.company else 'Lock' end
      activity_comp.base_rent = if unlockFields.include?"base_rent" then number_to_currency(activity_comp.base_rent.to_f, {:precision=>2}) else 'Lock' end
      activity_comp.net_effective_per_sf = if unlockFields.include?"net_effective_per_sf" then number_with_precision(activity_comp.net_effective_per_sf,:precision => 2) else "-0.0" end

    else
      activity_comp = activity.sale_record
      
      activity_comp.price = if unlockFields.include?"price" then number_to_currency(activity_comp.price.to_f, {:precision=>2}) else '-0.0' end
      activity_comp.land_size = if unlockFields.include?"land_size" then activity_comp.land_size else '-0.0' end
      ##activity_comp.net_effective_per_sf = if unlockFields.include?"net_effective_per_sf" then number_with_precision(activity_comp.net_effective_per_sf,:precision => 2) else "-0" end

    end

      activity
  end
  
end