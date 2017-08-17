class ConnectionRequest < ActiveRecord::Base

  default_scope {order('created_at DESC')}

  belongs_to :sender, class_name: 'User', foreign_key: 'user_id'
  belongs_to :receiver, class_name: 'User', foreign_key: 'agent_id'


  scope :received_by, ->(user_id) { where("agent_id = #{user_id}", user_id ).all }
  scope :sent_by, ->(user_id) { where("user_id = #{user_id}", user_id ).all }



end
