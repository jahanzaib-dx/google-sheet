class CompRequestsController < ApplicationController

  before_filter :authenticate_user!


  def index
    direction = params[:direction]
    comp_type = params[:comp_type]

    if direction == 'incoming'

      if !comp_type.blank?

         @comp_requests=CompRequest.incoming_sale_lease(current_user.id,comp_type)
        # @comp_requests.each do |comp_request|
        #   comp = CompRequest.find(comp_request)
        #   comp.status='TRUE'
        #   comp.save
        # end
      else
        @comp_requests = CompRequest.received_by current_user.id,comp_type
      end
    else
      @comp_requests = CompRequest.initiated_by current_user.id,comp_type
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
      @compdata = SiteHelper.getComp(params[:cid],params[:type])

      #p @compdata

      comp = CompRequest.new()
      comp.comp_id = params[:cid]
      comp.initiator_id = current_user.id
      comp.receiver_id = @compdata.user_id
      comp.comp_type = params[:type]
      ##comp.save      
      if comp.save && comp.received_by.settings.email
        DxMailer.comp_request_unlock(comp)
      end  
      
      render json: {:status => :success}

    end
  end



  # DELETE /connection_requests/1
  # DELETE /connection_requests/1.json
  def destroy
    comp_requests = CompRequest.where(:id =>  params[:ids])
    comp_requests.each do |comp_request|
      comp_request.ignore (params[:comptype])
      ##comp_request.destroy      
      if comp_request.destroy && comp_request.initiated_by.settings.email
        DxMailer.comp_request_declined(comp_request)
      end
      
    end
    render json: {:status => :success}

  end
  
  def full_transparency
    
    if !params[:access].blank?
      
      comp_request = CompRequest.where(:id =>  params[:id]).first
        
      comp_request.create_full_transparency comp_request, params      
            
    end
      
      comp_request.destroy
   
    render json: {:status => :success}
  end
  
  def partial_popup
    comp_request = CompRequest.where(:id =>  params[:id]).first
    
    if comp_request.comp_type == 'lease'
      @comp_record = TenantRecord.where(:id => comp_request.comp_id).first
      render partial: "partial_popup_lease"
    elsif 
      @comp_record = SaleRecord.where(:id => comp_request.comp_id).first 
      render partial: "partial_popup_sale"
    end
   
    
  end
  
  def partial_transparency
    comp_request = CompRequest.where(:id =>  params[:partial_comp_id]).first
    
    comp_request.create_partial_tranprency comp_request, params    
    
    comp_request.destroy
    
    render json: {:status => :success}
  end


  private

  def is_comp_request_valid?( )
    return true

  end


end
