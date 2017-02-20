class MessagesController < ApplicationController

  before_filter :authenticate_user!


  before_filter :set_message, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!

  respond_to :html

  def index

    #--------Add message-----------------

    if params[:sendmessage] && params[:receiver_id]

      if params[:file]

        @message = Message.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :created_at => Date.today.to_time , :message => params[:m_message] , :file =>params[:file])

      elsif

      ##@message = Message.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :created_at => Date.today.to_time , :message => params[:m_message])
      @message = Message.create(:sender_id => current_user.id , :receiver_id => params[:receiver_id] , :message => params[:m_message])

      end

      ruser = User.find(params[:receiver_id])

      ## send email
      @message = Message.find(@message.id)
      DxMailer.message_notification(ruser, @message).deliver


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

    @user_all_connections = Connection.all_connections_of_user(current_user.id)

    #--------delete message-----------------

    if params[:deletemessage] && params[:f_receiver_id].to_i > 0
      Message.deleteMessages(current_user,params[:f_receiver_id])
      redirect_to messages_path(mtype: @mtype)
      return
    end

    ##--------get user messages-----------

    if params[:f_receiver_id].to_i > 0
      selected_user_id = params[:f_receiver_id]
      @selected_user = User.find(selected_user_id)
      Message.markAsRead(current_user,selected_user_id)
    elsif
      selected_user_id = @user_connections.first
      @selected_user = User.find(selected_user_id)
    end

    if @selected_user
      ##Message.markAsRead(current_user,selected_user_id) ##moved in selected user if
    end

    @user_messages = Message.getUserMessages(current_user,selected_user_id)

    ##--------Mark as unread-----------

    if params[:mark_as_unread] && params[:f_receiver_id].to_i > 0

      Message.markAsUnread(current_user,params[:f_receiver_id])
      redirect_to messages_path(mtype: @mtype)
      return
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


=begin
  def index
    condition = params[:condition]
    case condition
      when 'unread'
        @messages = Message.not_read_by(current_user.id)
      when 'connections'
        initiated_connections = Connection.initiated_connections_of(current_user.id).pluck(:agent_id)
        approved_connections = Connection.approved_connections_of(current_user.id).pluck(:user_id)
        all_connections = initiated_connections + approved_connections

        received_messages = Message.received_by(current_user.id).sent_by_connections( all_connections )
        sent_messages = Message.sent_by(current_user.id).received_by_connections( all_connections )

        @messages = received_messages + sent_messages

        @messages.inspect

      else

    end

  end


  # POST /connection_requests
  # POST /connection_requests.json
  # TODO:
  def create
    parameters = connection_request_params
    if is_connection_request_valid? parameters[:agent_id]

      @connection_request = ConnectionRequest.new(parameters)

      if @connection_request.save
        render json: {:status => :success, :data => @connection}
      else
        render json: {:status => :error, :data => @connection_request.errors}
      end

    end
  end



  # DELETE /connection_requests/1
  # DELETE /connection_requests/1.json
  def destroy

    @connection_request = ConnectionRequest.find(params[:id])
    @connection_request.destroy

    render json: {:status => :success, :data => @connection_request}
  end


  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def connection_request_params
    params.fetch(:connection_request).permit(:agent_id)
  end



  def is_connection_request_valid?( other_id )
    return true
    error = ''
    if current_user.mobile.nil?  or !current_user.mobile_active
      error = 'Please enter and verify your mobile number first'
    else
      connection = Connection.where(:user_id => current_user.id, :agent_id => other_id).count
      if connection > 0
        error = 'You are already connected to selected user'
      else
        reverse_connection = Connection.where(:user_id => other_id, :agent_id =>  current_user.id).count
        if reverse_connection > 0
          error = 'You are already connected to selected user'
        end
      end
    end


    unless error == ''
      render json: {:status => :error, :data => error }
      return false
    end

    return true
  end
=end


end
