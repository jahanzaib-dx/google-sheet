class MessagesController < ApplicationController
  before_filter :set_message, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!

  respond_to :html

  def index
  		
		#--------Add message-----------------
		
  		if params[:sendmessage] && params[:receiver_id]
			
			if params[:file]
			
				Message.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :created_at => Date.today.to_time , :message => params[:m_message] , :file =>params[:file])
				
			elsif	
			
				Message.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :created_at => Date.today.to_time , :message => params[:m_message])
			
			end
			
			ruser = User.find(params[:receiver_id])
			
			## send email
			DxMailer.message_notification(ruser,params[:m_message]).deliver
			
			
		end
  		
		#--------Add message-----------------
		
		search = nil
		
		if params[:search] &&  params[:search].strip.length > 0
			search = params[:search]
		end
  
  		if params[:mtype] == 'connections'
			@user_connections = Message.getConnections(current_user,search)
			@mtype = 'connections'
		
		elsif params[:mtype] == 'unread'
			@user_connections = Message.getUnreadMessages(current_user,search)
			con_length = @user_connections.length
			
			@mtype = 'unread'
		else
		 	@user_connections = Message.getConnectionsByMessage(current_user,search)
			
			@mtype = 'all'
		end
		
		#--------delete message-----------------
		
		if params[:deletemessage] && params[:f_receiver_id]
			Message.deleteMessages(current_user,params[:f_receiver_id])
			redirect_to messages_path(mtype: @mtype)
			return
		end
		
		##--------get user messages-----------
		
		if params[:f_receiver_id]
			selected_user_id = params[:f_receiver_id]
			@selected_user = User.find(selected_user_id)
		elsif
			selected_user_id = @user_connections.first
			@selected_user = User.find(selected_user_id)
		end		
		
		if @selected_user
			Message.markAsRead(current_user,selected_user_id)
		end
		
		@user_messages = Message.getUserMessages(current_user,selected_user_id)
		
		##--------Mark as unread-----------
		
		if params[:mark_as_unread] && params[:f_receiver_id]
			Message.markAsUnread(current_user,params[:f_receiver_id])
			##redirect_to messages_path(mtype: @mtype)
			##return
		end
		
		
	##--------render-----------
	
	render "messages"
  end

  def farword
  
  	Message.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :created_at => Date.today.to_time , :message => params[:for_message] , :file =>"")
	
  	if params[:mtype]
		@mtype = params[:mtype]
	end
    redirect_to messages_path(mtype: @mtype)
  end
  
  def show
    respond_with(@message)
  end

  def new
    @message = Message.new
    respond_with(@message)
  end

  def edit
  end

  def create
    @message = Message.new(params[:message])
    @message.save
    respond_with(@message)
  end

  def update
    @message.update_attributes(params[:message])
    respond_with(@message)
  end

  def destroy
    @message.destroy
    respond_with(@message)
  end
  
  def connections
  	@user_connections = Connection.getConnections(current_user,'all');
	respond_to do |format|
     
        format.html { render :action => "_connections_ajax" }
        format.js
     
	end
  end

  private
    def set_message
      @message = Message.find(params[:id])
    end
end
