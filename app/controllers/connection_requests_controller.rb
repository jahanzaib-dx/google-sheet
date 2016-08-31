class ConnectionRequestsController < ApplicationController

  before_filter :authenticate_user!


  def index
    direction = params[:direction]
    if direction == 'incoming'
      @connection_requests = ConnectionRequest.received_by current_user.id
    else
      @connection_requests = ConnectionRequest.sent_by current_user.id
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


end
