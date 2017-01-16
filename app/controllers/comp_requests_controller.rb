class CompRequestsController < ApplicationController

  before_filter :authenticate_user!


  def index
    direction = params[:direction]
    comp_type = params[:comp_type]

    if direction == 'incoming'

      if !comp_type.blank?

         @comp_requests=CompRequest.incoming_sale_lease(current_user.id,comp_type)
        # @comp_requests.each do |comp_request|
        #   comp = CompRequest.find(comp_request)
        #   comp.status='TRUE'
        #   comp.save
        # end
      else
        @comp_requests = CompRequest.received_by current_user.id,comp_type
      end
    else
      @comp_requests = CompRequest.initiated_by current_user.id,comp_type
    end

  end

  def remind

    @comp_request = CompRequest.find(params[:id])

    if @comp_request.received_by.settings.email
      DxMailer.outgoing_reminder(@comp_request).deliver
    end
    render :json => {:status => 'success'}

  end

  def update
    comp_requests = CompRequest.where(:id => params[:ids])
    comp_requests.each do |comp_request|
      comp_request.approve (params[:access])
      comp_request.destroy
    end

    render json: {:status => :success}
  end



  # POST /connection_requests
  # POST /connection_requests.json

  def create
    if is_comp_request_valid?
      # TODO:
      @compdata = SiteHelper.getComp(params[:cid],params[:type])

      #p @compdata

      comp = CompRequest.new()
      comp.comp_id = params[:cid]
      comp.initiator_id = current_user.id
      comp.receiver_id = @compdata.user_id
      comp.comp_type = params[:type]
      ##comp.save
      
      ##p comp.received_by.settings.email
      
      comp.save()
      
      if comp.received_by.settings.email
        DxMailer.comp_request_unlock(comp).deliver
      end
      ##receiver_user = User.find(comp.receiver_id)
      ##DxMailer.comp_request_unlock(receiver_user,current_user,comp)
      
      render json: {:status => :success}

    end
  end



  # DELETE /connection_requests/1
  # DELETE /connection_requests/1.json
  def destroy
    comp_requests = CompRequest.where(:id =>  params[:ids])
    comp_requests.each do |comp_request|
      comp_request.ignore (params[:comptype])
      
      
      if comp_request.initiated_by.settings.email
        DxMailer.comp_request_declined(comp_request).deliver
      end
      
      ##log_my_activity comp_request, comp_request.initiator_id
      
      comp_request.destroy
      
    end
    render json: {:status => :success}

  end
  
  def full_transparency
    
    if !params[:access].blank?
      
      comp_requests = CompRequest.where(:id =>  params[:ids])
      
      comp_requests.each do |comp_request|
        CompRequest.create_full_transparency comp_request, params  
      end
      
      
        
      # shared = SharedComp.new()
      # shared.comp_id = comp_request.comp_id
      # shared.agent_id = comp_request.initiator_id
      # shared.comp_type = comp_request.comp_type
      # shared.comp_status = 'full'
      # shared.ownership = params[:access]=='full' ? true : false
      # shared.save
#       
      # if shared.ownership
        # ##duplicate comp in agent database
        # if shared.comp_type == 'lease'
          # comp_record = TenantRecord.where(:id =>  shared.comp_id).first
          # comp_record_new = TenantRecord.new()
        # elsif  
          # comp_record_new = SaleRecord.new()
        # end
#         
           # comp_record_new = comp_record.dup
           # comp_record_new.user_id = comp_request.initiator_id
           # comp_record_new.save
#         
      # end
            
    end
    
    ##comp_requests = CompRequest.where(:id => params[:ids])
    ##comp_requests.each do |comp_request|
      ##comp_request.approve (params[:access])
      
      
    ##end

    render json: {:status => :success}
  end
  
  def partial_popup
    comp_request = CompRequest.where(:id =>  params[:id]).first
    
    if comp_request.comp_type == 'lease'
      @comp_record = TenantRecord.where(:id => comp_request.comp_id).first
      render partial: "partial_popup_lease"
    elsif 
      @comp_record = SaleRecord.where(:id => comp_request.comp_id).first 
      render partial: "partial_popup_sale"
    end
   
    
  end

  def partial_transparency
    comp_request = CompRequest.where(:id =>  params[:partial_comp_id]).first
    
    CompRequest.create_partial_tranprency comp_request, params
    
    # params[:unlock].each do |unlock|
      # unlock_field = CompUnlockField.new()
      # unlock_field.field_name = unlock[0]
      # unlock_field.shared_comp_id = comp_request.comp_id
      # unlock_field.save
    # end
    
    comp_request.destroy
    
    ##render :template => "comp_requests/partial_popup"
    ##render partial: "partial_popup_lease"
    render json: {:status => :success}
  end

##-------------------------------------------------------------------

  def relock_comp

    ##if !params[:access].blank?
      
      activity_log = ActivityLog.where(:id =>  params[:activity_id]).first
      
      shared = SharedComp.where(:comp_id => activity_log.comp_id, :agent_id => activity_log.initiator_id, :comp_type => activity_log.comptype)
      
      if shared.count == 1
        shared = shared.first
        comp_unlock_field = CompUnlockField.where(:shared_comp_id => shared.id)
        comp_unlock_field.destroy_all
                 
        shared.destroy
      end
      
      activity_log.status = "Rejected"
      activity_log.save()

    render json: {:status => :success}
  end
  
  
  # def partial_transparency_update
#     
    # activity_log = ActivityLog.where(:id =>  params[:id])
#       
      # shared = SharedComp.where(:comp_id => activity_log.comp_id, :initiator_id => activity_log.agent_id, :comp_type => activity_log.comptype)
#       
      # if shared.count == 1
#         
        # shared.status = CompRequest.PARTIAL
        # shared.save()
#         
        # comp_unlock_field = CompUnlockField.where(:shared_comp_id => SharedComp.id)
        # comp_unlock_field.destroy_all
#         
        # params[:unlock].each do |unlock|
          # unlock_field = CompUnlockField.new()
          # unlock_field.field_name = unlock[0]
          # unlock_field.shared_comp_id = shared.id
          # unlock_field.save
        # end
#         
        # activity_log.status = "Approved"
        # activity_log.save()
#          
        # ##SharedComp.destroy
      # end
# 
    # render json: {:status => :success}
#     
  # end
  
  
  def full_transparency_update
    
    activity_log = ActivityLog.where(:id =>  params[:id])
            
      if activity_log.count == 1
         activity_log = activity_log.first
         
         shared = SharedComp.where(:comp_id => activity_log.comp_id, :agent_id => activity_log.initiator_id, :comp_type => activity_log.comptype)
        
        if shared.count < 1
          shared = SharedComp.new()
        else
          shared = shared.first
        end
        
        
        shared.comp_id = activity_log.comp_id
        shared.agent_id = activity_log.initiator_id
        shared.comp_type = activity_log.comptype
        
        shared.comp_status = CompRequest::FULL
        shared.ownership = params[:access]==CompRequest::FULL ? true : false
        
        
       if shared.ownership
          ## select lease or sale
          if shared.comp_type == 'lease'
            comp_record = TenantRecord.where(:id =>  shared.comp_id).first
            pkid = TenantRecord.maximum(:id).to_i.next
            comp_record_new = TenantRecord.new()
          elsif
          comp_record = SaleRecord.where(:id =>  shared.comp_id).first
            pkid = SaleRecord.maximum(:id).to_i.next
            comp_record_new = SaleRecord.new()
          end
    
          ##duplicate comp in agent database
          comp_record_new = comp_record.dup
          comp_record_new.id = pkid
          comp_record_new.user_id = activity_log.initiator_id
          comp_record_new.save
    
          shared.comp_status = CompRequest::FULL_OWNER
      end
      
      shared.save()
        
        # activity_log.status = "Approved"
        # activity_log.save()
        
        activity_log.status = shared.comp_status
        activity_log.save()
         
        ##SharedComp.destroy
      end
      
      

    render json: {:status => :success}
    
  end
  
  
  
  

   def partial_popup_edit
  
    activity_log = ActivityLog.where(:id =>  params[:id])

    if activity_log.count == 1
      activity_log = activity_log.first
        
        @unlockFields = SharedComp.getUnlockData activity_log
        
        p @unlockFields
        
      if activity_log.comptype == 'lease'
        @comp_record = TenantRecord.where(:id => activity_log.comp_id).first
        render partial: "partial_popup_lease_edit"
      elsif
        @comp_record = SaleRecord.where(:id => activity_log.comp_id).first
        render partial: "partial_popup_sale_edit"
      end

    end

  end

  def partial_transparency_update
    
    activity_log = ActivityLog.where(:id =>  params[:id])
    
    if activity_log.count == 1
         activity_log = activity_log.first
         
         shared = SharedComp.where(:comp_id => activity_log.comp_id, :agent_id => activity_log.initiator_id, :comp_type => activity_log.comptype)
        
        if shared.count < 1
          shared = SharedComp.new()
        else
          shared = shared.first
        end
        
        
        shared.comp_id = activity_log.comp_id
        shared.agent_id = activity_log.initiator_id
        shared.comp_type = activity_log.comptype
        
        shared.comp_status = CompRequest::PARTIAL
        shared.ownership = false
        
        shared.save()
        
        comp_unlock_field = CompUnlockField.where(:shared_comp_id => shared.id)
        comp_unlock_field.destroy_all
        
        params[:unlock].each do |unlock|
          unlock_field = CompUnlockField.new()
          unlock_field.field_name = unlock[0]
          unlock_field.shared_comp_id = shared.id
          unlock_field.save
        end
        
        # activity_log.status = "Approved"
        # activity_log.save()
        
        activity_log.status = shared.comp_status
        activity_log.save()
        
    end

    render json: {:status => :success}
  end
  
  
  private

  def is_comp_request_valid?( )
    return true

  end


end
