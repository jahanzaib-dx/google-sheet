class DatabaseBackEndsController < ApplicationController
  def index
  @custom_records = CustomRecord.where('user_id = ?', @current_user.id)
  end

  def upload_image
    require 'socket'
    if(params[:type]=='sale')
      @file = BackEndSaleComp.save_file(params)
    else
      if(params[:type]=='lease')
      @file = BackEndLeaseComp.save_file(params)
      else
        @file = BackEndCustomRecord.save_file(params)
      end
    end
    p request.domain+@file
    render :json => {
        :file_name => @file
    }
  end
end

