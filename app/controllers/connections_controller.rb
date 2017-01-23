class ConnectionsController < ApplicationController

  before_filter :authenticate_user!


  def create

    request = ConnectionRequest.find(params[:request_id])

    if is_connection_valid? request
      DxMailer.connection_request_approved_email(request).deliver
      connection_params = {:user_id => request.user_id, :agent_id => request.agent_id}
      @connection = Connection.new(connection_params)
      @connection.connection_established = true
      if @connection.save
        request.destroy
        respond_to do |format|
          format.html  { redirect_to connections_url }
          format.json  { render :json => {:status => :success, :data => @connection} }
        end
      else
        respond_to do |format|
          format.html  { redirect_to connections_url }
          format.json  { render :json => {:status => :success, :data => @connection.errors} }
        end
      end

    end
  end


  
  def index
		@connections = Connection.all_connections_of_user(current_user.id)
  end



  def destroy
    @connection = Connection.find(params[:id])
    if @connection.belongs_to_user? current_user.id
       @connection.destroy
       render json: {:status => :success, :data => @connection}
    end
  end




  def is_connection_valid?( request )
    return true
    error = ''
    if current_user.mobile.nil?  or !current_user.mobile_active
      error = 'Please enter and verify your mobile number first'
    else
      other_id = request.user_id == current_user.id ? request.agent_id : request.user_id
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
 

end
