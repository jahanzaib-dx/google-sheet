class Connection < ActiveRecord::Base

  #default_scope {order('created_at DESC')}

  belongs_to :user
  belongs_to :connected_to, class_name: 'User', foreign_key: :agent_id

  scope :all_connections_of_user, ->(user_id) { where("user_id = #{user_id} OR agent_id = #{user_id} ", user_id ).all }
  scope :initiated_connections_of, ->(user_id) { where("user_id = #{user_id} ", user_id ).all }
  scope :approved_connections_of, ->(user_id) { where("agent_id = #{user_id} ", user_id ).all }


  def belongs_to_user? id
    user_id == id or agent_id == id
  end




end
