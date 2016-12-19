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

end
