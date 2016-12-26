class CompRequest < ActiveRecord::Base

  default_scope {order('created_at DESC')}


  belongs_to :tenant_record, foreign_key: :comp_id
  belongs_to :sale_record, foreign_key: :comp_id
  belongs_to :initiated_by, class_name: 'User', foreign_key: :initiator_id
  belongs_to :received_by, class_name: 'User', foreign_key: :receiver_id

  belongs_to :outgoing_comp_requests, class_name: 'User', foreign_key: :initiator_id
  belongs_to :incoming_comp_requests, class_name: 'User', foreign_key: :receiver_id


  scope :received_by, ->(user_id,comp_type) { where("receiver_id = #{user_id} AND comp_requests.comp_type='#{comp_type}'", user_id ).all }
  scope :initiated_by, ->(user_id,comp_type) { where("initiator_id = #{user_id} AND comp_requests.comp_type='#{comp_type}'", user_id ).all }


  FULL     = "full"
  PARTIAL     = "partial"
  
  #scope :lease_requests, ->(){ join(:tenant_record).where("tenant_record.") }



  def log_activity status , comptype='lease'
    ##parameters = {:comp_id => comp_id, :receiver_id => receiver_id, :sender_id => initiator_id, :status => status}
    parameters = {:comp_id => comp_id, :receiver_id => receiver_id, :initiator_id => initiator_id, :status => status, :comptype => comptype}
    activity_log = ActivityLog.new(parameters)
    activity_log.save()
  end


  def approve (access)
    # access can be default, partial or full


    log_activity access
  end

  def ignore comptype
    log_activity 'Rejected' , comptype
  end

  # def self.incoming_sale_lease(user_id, comp_type)
  #   comp_request = joins(:tenant_record).where('receiver_id = ? and record_type Like ? and status = ? ',user_id,comp_type,false).all
  #   comp_request
  # end

  def self.incoming_sale_lease(user_id, comp_type)
    if comp_type == 'lease'
      comp_request = joins(:tenant_record).where('receiver_id = ? and comp_requests.comp_type Like ? ',user_id,comp_type).all
    else
      comp_request = joins(:sale_record).where('receiver_id = ? and comp_requests.comp_type Like ? ',user_id,comp_type).all
    end
    comp_request
  end
  
  def self.log_my_activity comp_request, curent_user
    parameters = {:comp_id => comp_request.comp_id, :receiver_id => comp_request.agent_id, :initiator_id => curent_user, :status => comp_request.comp_status, :comptype => comp_request.comp_type}
    activity_log = ActivityLog.new(parameters)
    activity_log.save()
  end
  
  def self.create_full_transparency comp_request, params  
      ## save in shared comp
      shared = SharedComp.new()
      shared.comp_id = comp_request.comp_id
      shared.agent_id = comp_request.initiator_id
      shared.comp_type = comp_request.comp_type
      shared.comp_status = FULL
      shared.ownership = params[:access]==FULL ? true : false
      ##shared.save
      
      if shared.save && comp_request.initiated_by.settings.email
        DxMailer.comp_request_approved(comp_request)
      end
      
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
           comp_record_new.user_id = comp_request.initiator_id
           comp_record_new.save
        
      end
      comp_request.destroy
      log_my_activity shared, comp_request.initiator_id
    
    end
    
    def create_partial_tranprency comp_request, params
      
      shared = SharedComp.new()
      shared.comp_id = comp_request.comp_id
      shared.agent_id = comp_request.initiator_id
      shared.comp_type = comp_request.comp_type
      shared.comp_status = PARTIAL
      shared.ownership = false
      shared.save
      
      if shared.save && comp_request.initiated_by.settings.email
        DxMailer.comp_request_approved(comp_request)
      end
      
      ## save each field name in Comp_unlock_field table
      params[:unlock].each do |unlock|
        unlock_field = CompUnlockField.new()
        unlock_field.field_name = unlock[0]
        unlock_field.shared_comp_id = shared.id
        unlock_field.save
      end
      
      log_my_activity shared, comp_request.initiator_id
      
    end

end
