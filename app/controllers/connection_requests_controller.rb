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
  def create
    if !current_user.can_send_requests?
      session[:after_mobile_verfication_redirect] = connections_url
      render json: {:status => :error, :issue => 'Mobile Validation',  :message => 'Please enter and verify your mobile number first', :url => profile_update_path}
      flash[:error] = 'You need to complete your profile before adding connections.'
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


  def accept
    @connection_request = ConnectionRequest.find(params[:id])
    # request = ConnectionRequest.find(params[:id])
    # DxMailer.connection_request_approved_email(request).deliver
    if user_signed_in?
      if current_user.email != @connection_request.receiver.email
        if User.find(@connection_request.receiver.id).first_name.blank?
          User.find(@connection_request.receiver.id).destroy
          @connection_request.agent_id = current_user.id
          @connection_request.save
          @connection_request.receiver = current_user
        end
      end

      if @connection_request.receiver.can_send_requests?
        redirect_to connections_internal_create_url(:request_id=>@connection_request.id)
      else
        session[:after_mobile_verfication_redirect] = accept_connection_request_url(@connection_request.id)
        redirect_to verifications_verify_url
      end
    else
      if !User.find(@connection_request.receiver.id).first_name.blank?
        session[:after_login_redirect] = accept_connection_request_url(@connection_request.id)
        redirect_to new_user_session_url
      else
      #session[:after_login_redirect] = accept_connection_request_url(@connection_request.id)
      redirect_to new_user_session_url
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
      agent = User.where(:email => params[:email]).first
      if ConnectionRequest.where(:user_id => current_user.id, :agent_id => agent.id).count == 0
        @connection_request = ConnectionRequest.new(parameters)
        if @connection_request.save

          request = ConnectionRequest.find( @connection_request.id )
          DxMailer.connection_invite(request).deliver

          render json: {:status => :success, :data => @connection_request}

        else
          render json: {:status => :error, :data => @connection_request.errors}
        end
      else
        request = ConnectionRequest.where(:user_id => current_user.id, :agent_id => agent.id)
        DxMailer.connection_invite(request.last).deliver
        render json: {:status => :success, :data => @connection_request}
      end
    end



end
