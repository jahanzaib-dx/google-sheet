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
    if !current_user.can_send_requests?
      render json: {:status => :error, :message => 'Please enter and verify your mobile number first' }
      return
    else
      agent = User.where(:email => params[:email]).first
      if(agent != nil)
        connection = Connection.where(:user_id => current_user.id, :agent_id => agent.id).count
        if connection > 0
          render json: {:status => :error, :message => 'You are already connected to selected user' }
          return
        else
          reverse_connection = Connection.where(:user_id => agent.id, :agent_id =>  current_user.id).count
          if reverse_connection > 0
            render json: {:status => :error, :message=> 'You are already connected to selected user' }
            return
          else
            request = {:user_id => current_user.id, :agent_id => agent.id, :message => params[:p_message]}
            add request
            return
          end
        end
      else
        # generate a random connection code
        # create dummy user and add request for that user
        # send invite email containig that code

        #random_key = ('a'..'z').to_a.shuffle[0,8].join
        agent = User.new
        agent.email = params[:email]
        agent.skip_confirmation!
        if agent.save(validate: false)
          request = {:user_id => current_user.id, :agent_id => agent.id, :message => params[:p_message]}
          add request
          return
        end
        return
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
      params.fetch(:connection_request).permit(:agent_id, :message)
    end

    def add parameters
      @connection_request = ConnectionRequest.new(parameters)
      if @connection_request.save

        request = ConnectionRequest.find( @connection_request.id )
        DxMailer.connection_invite(request).deliver

        render json: {:status => :success, :data => @connection_request}

      else
        render json: {:status => :error, :data => @connection_request.errors}
      end
    end



end
