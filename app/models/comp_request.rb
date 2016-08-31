class CompRequest < ActiveRecord::Base

  default_scope {order('created_at DESC')}


  belongs_to :tenant_record, foreign_key: :comp_id
  belongs_to :initiated_by, class_name: 'User', foreign_key: :initiator_id
  belongs_to :received_by, class_name: 'User', foreign_key: :receiver_id


  scope :received_by, ->(user_id) { where("receiver_id = #{user_id}", user_id ).all }
  scope :initiated_by, ->(user_id) { where("initiator_id = #{user_id}", user_id ).all }


  #scope :lease_requests, ->(){ join(:tenant_record).where("tenant_record.") }



  def log_activity status
    parameters = {:comp_id => comp_id, :receiver_id => receiver_id, :sender_id => initiator_id, :status => status}
    activity_log = ActivityLog.new(parameters)
    activity_log.save()
  end


  def approve (access)
    # access can be default, partial or full
    log_activity access
  end

  def ignore
    log_activity 'Rejected'
  end

end
