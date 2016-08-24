class Message < ActiveRecord::Base

  mount_uploader :file, FileUploader

  belongs_to :sender, class_name: :user
  belongs_to :receiver, class_name: :user

  
  def self.getConnectionsByMessage(user,search)
  	
	if search
	
		####user_connections = Messages.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = messages.sender_id").joins("LEFT JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*").where("sender.username LIKE ? OR receiver.username LIKE ?" , "%#{search}%" , "%#{search}%")
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from messages where sender_id = ? or receiver_id = ? UNION SELECT receiver_id from messages where sender_id = ? or receiver_id = ?) AND id != ?",user.id,user.id,user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')
		
	else 
	
		###user_connections = Messages.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("inner JOIN users sender ON sender.id = messages.sender_id").joins("inner JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*")
		
		##user_connections = Messages.select("DISTINCT on (sender_id,receiver_id) *").where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("inner JOIN users sender ON sender.id = messages.sender_id").joins("inner JOIN users receiver ON receiver.id = messages.receiver_id")
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from messages where sender_id = ? or receiver_id = ? UNION SELECT receiver_id from messages where sender_id = ? or receiver_id = ?) AND id != ?",user.id,user.id,user.id,user.id,user.id).order('id DESC')
		
		##SELECT sender_id as user_ids from messages UNION SELECT receiver_id from messages
	
	end
	
	return user_connections
	
  end
  
  #-------------------------------------------------------
  
  def self.getConnections(user,search)
  	
	if search
		
		user_connections = Connections.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("connections.status" => 2).where("users.username LIKE ? " , "%#{search}%" ).order('connections.id DESC')
		
	else 
	
		user_connections = Connections.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("connections.status" => 2).order('connections.id DESC')
	
	end
	
	return user_connections
	
  end
  
  #-------------------------------------------------------
  
  def self.getUnreadMessages(user,search)
  	
	if search
		
		###user_connections = Messages.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = messages.sender_id").joins("LEFT JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*").where("sender.username LIKE ? OR receiver.username LIKE ?" , "%#{search}%" , "%#{search}%").where("messages.status = false")
		
		###user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (sender_id = ? or receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (sender_id = ? or receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')
		
	else 
	
		###user_connections = Messages.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = messages.sender_id").joins("LEFT JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*").where("messages.status = false")
		
		#####user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (sender_id = ? or receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (sender_id = ? or receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id,user.id,user.id).order('id DESC')
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id).order('id DESC')
		
	
	end
	
	return user_connections
	
  end
  
  #-------------------------------------------------------
  
  def self.getUserMessages(user,selected_user_id)
  	user_messages = Messages.where("(messages.sender_id = ? AND messages.receiver_id = ?) OR ( messages.receiver_id = ? AND messages.sender_id = ?)" , user.id,selected_user_id,user.id,selected_user_id).order('messages.created_at ASC')
	
  end
  
   #-------------------------------------------------------
  
  def self.getAllUserMessages(user)
  	user_messages = Messages.where("(messages.sender_id = ? OR messages.receiver_id = ?)" , user.id,user.id)
	
  end
  
  #-------------------------------------------------------
  
  def self.getAllUnreadMessages(user)
  	user_messages = Messages.where("(messages.receiver_id = ?) AND status = false" , user.id)
	
  end
  
   #-------------------------------------------------------
  
  def self.markAsRead(user,selected_user_id)
  	Messages.where("(messages.receiver_id = ?) AND status = false" , user.id).update_all("status = true")
	
  end
  
  
  
  
	 
#####end of class#############
end
