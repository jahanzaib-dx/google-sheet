class ActivityLog < ActiveRecord::Base

  default_scope {order('created_at DESC')}

  belongs_to :tenant_record, foreign_key: :comp_id
  belongs_to :sale_record, foreign_key: :comp_id
  belongs_to :initiated_by, class_name: 'User', foreign_key: :initiator_id
  belongs_to :received_by, class_name: 'User', foreign_key: :receiver_id

  scope :all_activities_of_user, ->(user_id) { where("initiator_id = #{user_id} OR receiver_id = #{user_id} ", user_id ) }
  
  scope :all_activities_with_type, ->(user_id,comptype) { where("(initiator_id = #{user_id} OR receiver_id = #{user_id}) AND comptype = '#{comptype}' ", user_id,comptype ) }
  
  scope :my_all_activities, ->(user_id,comptype) { where("(receiver_id = #{user_id}) AND comptype = '#{comptype}' ", user_id,comptype ) }
  
  TIRES = { "full" => "Tire 2", "partial" => "Tire 3", "full_owner" => "Tire 1" }

end