class BackEndCustomRecordController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  def index
    @custom_record_id = params[:id];
    @custom_record_properties = CustomRecordProperty.select(:key).distinct.where('custom_record_id=?',@custom_record_id)

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

    check = BackEndCustomRecord.where('custom_record_id = ?', @custom_record_id)
    if  check.count == 0
      @file = session.drive.copy_file('1Ey15FKMBqr8oNsGRXnRrSvUxPoWTgJwLmi3wkSV76Tk', {name: fileName}, {})

      # put data to sheet
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
      col=1
      @custom_record_properties.each do |crp|
        row=1
        ws[row,col] = crp.key
        row+=1
        @crp_values = CustomRecordProperty.select(:value).where('key = ? and custom_record_id = ?', crp.key,@custom_record_id)
        @crp_values.each do |crp_value|
          ws[row, col] = crp_value.value
          row+=1
        end
        col+=1
      end
      ws.save()

      @BackEndCustonRecord = BackEndCustomRecord.new
      @BackEndCustonRecord.custom_record_id = @custom_record_id
      @BackEndCustonRecord.file = @file.id
      @BackEndCustonRecord.save

      @file_temp = session.drive.copy_file(@file.id, {name: "#{@current_user.id}_temp"}, {})

      session.drive.batch do
        user_permission = {
            value: 'default',
            type: 'anyone',
            role: 'writer'
        }
        session.drive.create_permission(@file_temp.id, user_permission, fields: 'id')
      end
      @file = BackEndCustomRecord.where('custom_record_id = ?', @custom_record_id).first
    else
      @file = BackEndCustomRecord.where('custom_record_id = ?', @custom_record_id).first
      ws = session.spreadsheet_by_key(@file.file).worksheets[0]
      col=1
      @custom_record_properties.each do |crp|
        row=1
        ws[row,col] = crp.key
        row+=1
        @crp_values = CustomRecordProperty.select(:value).where('key = ? and custom_record_id = ?', crp.key,@custom_record_id)
        @crp_values.each do |crp_value|
          ws[row, col] = crp_value.value
          row+=1
        end
        col+=1
      end
      ws.save()

      @file_temp = session.drive.copy_file(@file.file, {name: "#{@current_user.id}_temp"}, {})
      session.drive.batch do
        user_permission = {
            value: 'default',
            type: 'anyone',
            role: 'writer'
        }
        session.drive.create_permission(@file_temp.id, user_permission, fields: 'id')
      end
    end
    render :json => {
        :file_temp => @file_temp.id,
        :file => @file.file,
        :custom_record_id => @custom_record_id
    }
  end


  def create
    @custom_record_id = params[:custom_record_id];
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    session.drive.delete_file(params[:id])
    @file = session.drive.copy_file("#{params[:temp]}", {name: params[:id]}, {})

    @BackEndCustomRecord = BackEndCustomRecord.where("custom_record_id = ?",@custom_record_id).first
    @BackEndCustomRecord.update_attributes(:file => @file.id)
    session.drive.delete_file(params[:temp])
    ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    @custom_record_properties = CustomRecordProperty.where("custom_record_id = ?",@custom_record_id)
    @custom_record_properties.destroy_all
    key=''
    (1..ws.num_cols).each do |col|
      (1..ws.num_rows).each do |row|
        p ws[row, col]
        if(row==1)
          key = ws[row,col]
          next
        else
          @custom_record_properties = CustomRecordProperty.new
          @custom_record_properties.custom_record_id = @custom_record_id
          @custom_record_properties.key = key
          @custom_record_properties.value = ws[row,col]
          @custom_record_properties.save
        end
      end
    end
    @file = BackEndCustomRecord.where('custom_record_id = ?', @custom_record_id).first

    @file_temp = session.drive.copy_file(@file.file, {name: "#{@current_user.id}_temp"}, {})
    session.drive.batch do
      user_permission = {
          value: 'default',
          type: 'anyone',
          role: 'writer'
      }
      session.drive.create_permission(@file_temp.id, user_permission, fields: 'id')
    end
    render :json => {
        :file_temp => @file_temp.id,
        :file => @file.file,
        :custom_record_id => @custom_record_id,
        :flag => 'custom'
    }
  end
end
