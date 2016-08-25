class Connection < ActiveRecord::Base

  belongs_to :user
  belongs_to :connected_to, class_name: 'User', foreign_key: :agent_id



  # -------------Setup accessible (or protected) attributes for your model ---------------
  #attr_accessible :user_id , :con_id , :status , :created_at , :group_id , :message
  
  def self.getConnections(user,type='all')
  	
	if type == 'all'
		user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).order('connections.id DESC')
	end
	
	if type == 'pending'
		user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("connections.status < ?" , 1).order('connections.id DESC')
		##user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:con_id=>user.id).where("connections.status" => 1).order('connections.id DESC')
	end
	
	if type == 'sent'
		user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("connections.status" => 1).order('connections.id DESC')
	end
	
	if type == 'accept'
		user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("connections.status" => 2).order('connections.id DESC')
	end
	
	if type == 'ignore'
		user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("connections.status" => 3).order('connections.id DESC')
	end
	
	return user_connections
	
  end
  
  def self.current_user_connections(user)
  	user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("connections.status" => 2).order('connections.id DESC').all
	
	user_connections_count = user_connections.count
	
	user_connections_return = "#{user_connections_count} Connection"
	
	if user_connections_count > 1
		user_connections_return = "#{user_connections_count} Connections"
	end
	
	return user_connections_return

  end
     
#####end of class#############
end
