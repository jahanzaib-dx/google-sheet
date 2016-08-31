class CompRequestsController < ApplicationController

  before_filter :authenticate_user!


  def index
    direction = params[:direction]
    if direction == 'incoming'
      @comp_requests = CompRequest.received_by current_user.id
    else
      @comp_requests = CompRequest.initiated_by current_user.id
    end

  end

  def remind

    @comp_request = CompRequest.find(params[:id])

    if @comp_request.received_by.settings.email
      DxMailer.outgoing_reminder(@comp_request)
    end
    render :json => {:status => 'success'}

  end

  def update
    comp_requests = CompRequest.where(:id => params[:ids])
    comp_requests.each do |comp_request|
      comp_request.approve (params[:access])
      comp_request.destroy
    end

    render json: {:status => :success}
  end



  # POST /connection_requests
  # POST /connection_requests.json

  def create
    if is_comp_request_valid?
      # TODO:
    end
  end



  # DELETE /connection_requests/1
  # DELETE /connection_requests/1.json
  def destroy

    comp_requests = CompRequest.where(:id => params[:ids])
    comp_requests.each do |comp_request|
      comp_request.ignore
      comp_request.destroy
    end
    render json: {:status => :success}

  end


  private

  def is_comp_request_valid?( )
    return true

  end


end
