class Message < ActiveRecord::Base

  #default_scope {order('created_at DESC')}

  mount_uploader :file, FileUploader

  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'

  scope :received_by, ->(user_id) { where("receiver_id = #{user_id}", user_id ) }
  scope :sent_by, ->(user_id) { where("sender_id = #{user_id}", user_id) }

  scope :received_by_connections, ->(connection_ids) { where("receiver_id in (?)", connection_ids) }
  scope :sent_by_connections, ->(connection_ids) { where( "sender_id in (?)",connection_ids) }


  scope :conversations, ->(user_id) { where("receiver_id = #{user_id} OR sender_id = #{user_id}", user_id ) }
  scope :not_read_by, ->(user_id) { where("receiver_id = #{user_id} AND status = false ", user_id ) }











  def self.getConnectionsByMessage(user,search)

    if search

      ####user_connections = Message.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = messages.sender_id").joins("LEFT JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*").where("sender.username LIKE ? OR receiver.username LIKE ?" , "%#{search}%" , "%#{search}%")

      user_connections = User.where("id in (SELECT sender_id as user_ids from messages where sender_id = ? or receiver_id = ? UNION SELECT receiver_id from messages where sender_id = ? or receiver_id = ?) AND id != ?",user.id,user.id,user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')

    else

      ###user_connections = Message.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("inner JOIN users sender ON sender.id = messages.sender_id").joins("inner JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*")

      ##user_connections = Message.select("DISTINCT on (sender_id,receiver_id) *").where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("inner JOIN users sender ON sender.id = messages.sender_id").joins("inner JOIN users receiver ON receiver.id = messages.receiver_id")

      user_connections = User.where("id in (SELECT sender_id as user_ids from messages where sender_id = ? or receiver_id = ? UNION SELECT receiver_id from messages where sender_id = ? or receiver_id = ?) AND id != ?",user.id,user.id,user.id,user.id,user.id).order('id DESC')

      ##SELECT sender_id as user_ids from messages UNION SELECT receiver_id from messages

    end

    return user_connections

  end

  #-------------------------------------------------------

  def self.getConnections(user,search)

    if search

      user_connections = Connection.joins("INNER JOIN users ON users.id = connections.agent_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).where("users.username LIKE ? " , "%#{search}%" ).order('connections.id DESC')

    else

      user_connections = Connection.joins("INNER JOIN users ON users.id = connections.agent_id").select("connections.*, users.* , connections.id as cid").where(:user_id=>user.id).order('connections.id DESC')

    end

    return user_connections

  end

  #-------------------------------------------------------

  def self.getUnreadMessages(user,search)

    if search

      ###user_connections = Message.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = messages.sender_id").joins("LEFT JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*").where("sender.username LIKE ? OR receiver.username LIKE ?" , "%#{search}%" , "%#{search}%").where("messages.status = false")

      ###user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (sender_id = ? or receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (sender_id = ? or receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')

      user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id).where("users.username LIKE ?" , "%#{search}%").order('id DESC')

    else

      ###user_connections = Message.where("messages.sender_id = ? OR messages.receiver_id = ?" , user.id,user.id).joins("LEFT JOIN users sender ON sender.id = messages.sender_id").joins("LEFT JOIN users receiver ON receiver.id = messages.receiver_id").select("messages.*, sender.* ,receiver.*").where("messages.status = false")

      #####user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (sender_id = ? or receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (sender_id = ? or receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id,user.id,user.id).order('id DESC')

      user_connections = User.where("id in (SELECT sender_id as user_ids from messages where (receiver_id = ?) AND status = false UNION SELECT receiver_id from messages where (receiver_id = ?) AND status = false) AND id != ?",user.id,user.id,user.id).order('id DESC')


    end

    return user_connections

  end

  #-------------------------------------------------------

  def self.getUserMessages(user,selected_user_id)
    user_messages = Message.where("(messages.sender_id = ? AND messages.receiver_id = ?) OR ( messages.receiver_id = ? AND messages.sender_id = ?)" , user.id,selected_user_id,user.id,selected_user_id).order('messages.created_at ASC').order('messages.id ASC')

  end

  #-------------------------------------------------------

  def self.getAllUserMessages(user)
    user_messages = Message.where("(messages.sender_id = ? OR messages.receiver_id = ?)" , user.id,user.id)

  end

  #-------------------------------------------------------

  def self.getAllUnreadMessages(user)
    user_messages = Message.where("(messages.receiver_id = ?) AND status = false" , user.id)

  end

  #-------------------------------------------------------

  def self.markAsRead(user,selected_user_id)
    Message.where("(messages.receiver_id = ?) AND status = false" , user.id).update_all("status = true")

  end

  #-------------------------------------------------------
  def self.deleteMessages(user,selected_user_id)
    Message.where("
	(messages.sender_id = ? AND messages.receiver_id = ?)
	OR
	(messages.receiver_id = ? AND messages.sender_id = ?)" ,
                   user.id,selected_user_id,user.id,selected_user_id)
    .destroy_all
  end

  #-------------------------------------------------------

  def self.getLastMessage(user,selected_user_id)
    last_message = Message.where("(messages.sender_id = ? AND messages.receiver_id = ?) OR ( messages.receiver_id = ? AND messages.sender_id = ?)" , user.id,selected_user_id,user.id,selected_user_id).order('messages.created_at desc')
    return last_message.first;

  end

  #-------------------------------------------------------

  def self.markAsUnread(user,selected_user_id)

    last_mess = Message.getLastMessage(user,selected_user_id)

    if last_mess.sender_id != user.id
      last_mess.update_attribute("status",false)
    end

  end











end
