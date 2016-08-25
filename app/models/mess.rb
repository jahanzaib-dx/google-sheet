class Mess < ActiveRecord::Base
 
  # -------------Setup accessible (or protected) attributes for your model ---------------
  #attr_accessible :sender_id , :receiver_id , :message , :created_at , :status , :file
     
  mount_uploader :file, FileUploader
  
  def self.getConnectionsByMessage(user,search)
  	
	if search
	
		####user_connections = Mess.where("mess.sender_id = ? OR mess.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = mess.sender_id").joins("LEFT JOIN users receiver ON receiver.id = mess.receiver_id").select("mess.*, sender.* ,receiver.*").where("sender.username LIKE ? OR receiver.username LIKE ?" , "%#{search}%" , "%#{search}%")
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from mess where sender_id = ? or receiver_id = ? UNION SELECT receiver_id from mess where sender_id = ? or receiver_id = ?) AND id != ?",user.id,user.id,user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')
		
	else 
	
		###user_connections = Mess.where("mess.sender_id = ? OR mess.receiver_id = ?" , user.id,user.id).joins("inner JOIN users sender ON sender.id = mess.sender_id").joins("inner JOIN users receiver ON receiver.id = mess.receiver_id").select("mess.*, sender.* ,receiver.*")
		
		##user_connections = Mess.select("DISTINCT on (sender_id,receiver_id) *").where("mess.sender_id = ? OR mess.receiver_id = ?" , user.id,user.id).joins("inner JOIN users sender ON sender.id = mess.sender_id").joins("inner JOIN users receiver ON receiver.id = mess.receiver_id")
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from mess where sender_id = ? or receiver_id = ? UNION SELECT receiver_id from mess where sender_id = ? or receiver_id = ?) AND id != ?",user.id,user.id,user.id,user.id,user.id).order('id DESC')
		
		##SELECT sender_id as user_ids from mess UNION SELECT receiver_id from mess
	
	end
	
	return user_connections
	
  end
  
  #-------------------------------------------------------
  
  def self.getConnections(user,search)
  	
	if search
		
		user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("users.username LIKE ? " , "%#{search}%" ).order('connections.id DESC')
		
	else 
	
		user_connections = Connection.joins("INNER JOIN users ON users.id = connections.con_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).order('connections.id DESC')
	
	end
	
	return user_connections
	
  end
  
  #-------------------------------------------------------
  
  def self.getUnreadMessages(user,search)
  	
	if search
		
		###user_connections = Mess.where("mess.sender_id = ? OR mess.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = mess.sender_id").joins("LEFT JOIN users receiver ON receiver.id = mess.receiver_id").select("mess.*, sender.* ,receiver.*").where("sender.username LIKE ? OR receiver.username LIKE ?" , "%#{search}%" , "%#{search}%").where("mess.status = false")
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from mess where (sender_id = ? or receiver_id = ?) AND status = false UNION SELECT receiver_id from mess where (sender_id = ? or receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')
		
	else 
	
		###user_connections = Mess.where("mess.sender_id = ? OR mess.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = mess.sender_id").joins("LEFT JOIN users receiver ON receiver.id = mess.receiver_id").select("mess.*, sender.* ,receiver.*").where("mess.status = false")
		
		user_connections = User.where("id in (SELECT sender_id as user_ids from mess where (sender_id = ? or receiver_id = ?) AND status = false UNION SELECT receiver_id from mess where (sender_id = ? or receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id,user.id,user.id).order('id DESC')
	
	end
	
	return user_connections
	
  end
  
  #-------------------------------------------------------
  
  def self.getUserMessages(user,selected_user_id)
  	user_messages = Mess.where("(mess.sender_id = ? AND mess.receiver_id = ?) OR ( mess.receiver_id = ? AND mess.sender_id = ?)" , user.id,selected_user_id,user.id,selected_user_id).order('mess.created_at ASC')
	
  end
  
   #-------------------------------------------------------
  
  def self.getAllUserMessages(user)
  	user_messages = Mess.where("(mess.sender_id = ? OR mess.receiver_id = ?)" , user.id,user.id)
	
  end
  
  #-------------------------------------------------------
  
  def self.getAllUnreadMessages(user)
  	user_messages = Mess.where("(mess.receiver_id = ?) AND status = false" , user.id)
	
  end
  
   #-------------------------------------------------------
  
  def self.markAsRead(user,selected_user_id)
  	user_messages = Mess.where("(mess.receiver_id = ?) AND status = false" , user.id)
	
  end
  
  
  
  
	 
#####end of class#############
end
