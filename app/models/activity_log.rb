class ActivityLog < ActiveRecord::Base

  default_scope {order('created_at DESC')}

  belongs_to :tenant_record, foreign_key: :comp_id
  belongs_to :initiated_by, class_name: 'User', foreign_key: :initiator_id
  belongs_to :received_by, class_name: 'User', foreign_key: :receiver_id

  scope :all_activities_of_user, ->(user_id) { where("initiator_id = #{user_id} OR receiver_id = #{user_id} ", user_id ) }

end