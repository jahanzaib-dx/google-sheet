class MessController < ApplicationController
  before_filter :set_message, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
  		
  		if params[:sendmessage] && params[:receiver_id]
			
			if params[:file]
			
				Mess.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :created_at => Date.today.to_time , :message => params[:m_message] , :file =>params[:file])
				
			elsif	
			
				Mess.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :created_at => Date.today.to_time , :message => params[:m_message])
			
			end
			
			ruser = User.find(params[:receiver_id])
			
			## send email
			DxMailer.message_notification(ruser,params[:m_message]).deliver
			
			
		end
  
		search = nil
		
		if params[:search] &&  params[:search].strip.length > 0
			search = params[:search]
		end
  
  		if params[:mtype] == 'connections'
			@user_connections = Mess.getConnections(current_user,search)
			@mtype = 'connections'
		
		elsif params[:mtype] == 'unread'
			@user_connections = Mess.getUnreadMessages(current_user,search)
			
			@mtype = 'unread'
		else
		 	@user_connections = Mess.getConnectionsByMessage(current_user,search)
			
			@mtype = 'all'
		end
		
		##--------get user messages-----------
		
		if params[:f_receiver_id]
			selected_user_id = params[:f_receiver_id]
			@selected_user = User.find(selected_user_id)
		elsif
			selected_user_id = @user_connections.first
			@selected_user = User.find(selected_user_id)
		end		
		
		@user_messages = Mess.getUserMessages(current_user,selected_user_id)
		
	
	render "mess"
  end

  def show
    respond_with(@mess)
  end

  def new
    @message = Mess.new
    respond_with(@mess)
  end

  def edit
  end

  def create
    @message = Mess.new(params[:message])
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
  	@user_connections = Connections.getConnections(current_user,'all');
	respond_to do |format|
     
        format.html { render :action => "_connections_ajax" }
        format.js
     
	end
  end

  private
    def set_message
      @message = Mess.find(params[:id])
    end
end
