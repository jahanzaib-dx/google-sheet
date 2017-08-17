class DatabaseBackEndsController < ApplicationController
  require "google_drive"
  def index
    require "google_drive"
    @custom_records = CustomRecord.where('user_id = ?', @current_user.id)
    DatabaseDeleteTempFileWorker.perform_async(@current_user.id)
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
  def export
    require 'socket'
    require "google_drive"
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
     path = "#{Rails.root}/public/uploads/export"
    file_id = params[:id]
    session.drive.export_file(file_id,
                   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                   download_dest: "#{path}/#{file_id}.xlsx")
    render :json => {
        :file => "http://"+request.host_with_port+"/uploads/export/"+file_id+".xlsx"
    }
  end
end

