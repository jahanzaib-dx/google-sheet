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
    render :json => {
        :file_name => "http://"+request.host_with_port+@file
    }
  end
end

