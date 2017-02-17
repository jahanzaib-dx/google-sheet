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

  def connection_name(current_user,c)
    if current_user.id == c.user_id
      return connected_to.first_name
    else
      return user.first_name
    end

  end

  def connection_fullname(current_user,c)
    if current_user.id == c.user_id
      unless connected_to.first_name.blank?
        "#{connected_to.first_name} #{connected_to.last_name}"
      else
        "<#{connected_to.email}>"
      end
      ##return connected_to.first_name
    else
      unless user.first_name.blank?
        "#{user.first_name} #{user.last_name}"
      else
        "<#{user.email}>"
      end
      ##return user.first_name
    end

  end

  def connection_id(current_user,c)
    if current_user.id == c.user_id
      ##return connected_to.account.id
      return c.agent_id
    else
      ##return user.account.id
      return c.user_id
    end

  end

  def self.all_connection_ids(current_user)
    @connection_ids = self.all_connections_of_user(current_user.id).collect {|c|
      if current_user.id == c.user_id
        c.agent_id
      else
        c.user_id
      end
    }
    return @connection_ids
  end




end
