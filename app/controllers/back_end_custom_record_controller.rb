class BackEndCustomRecordController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  def index
    sale_records = SaleRecord.where('user_id = ?', @current_user)

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

    check = BackEndSaleComp.where('user_id = ?', @current_user)
    if  check.count == 0
      @file = session.drive.copy_file('1Ey15FKMBqr8oNsGRXnRrSvUxPoWTgJwLmi3wkSV76Tk', {name: fileName}, {})

      # put data to sheet
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
      counter=2
      sale_records.each do |sale_record|
        # if sale_record.id!=counter-1
        #   ws[counter, 1] =  counter
        #   next
        # end
        ws[counter, 1] = sale_record.id
        ws[counter, 2] = sale_record.is_sales_record
        ws[counter, 3] = sale_record.land_size_identifier
        ws[counter, 4] = sale_record.view_type
        ws[counter, 5] = sale_record.address1
        ws[counter, 6] = sale_record.city
        ws[counter, 7] = sale_record.state
        ws[counter, 8] = sale_record.land_size
        ws[counter, 9] = sale_record.price
        ws[counter, 10] = sale_record.cap_rate
        ws[counter, 11] = sale_record.latitude
        ws[counter, 12] = sale_record.longitude
        ws[counter, 13] = sale_record.zipcode
        ws[counter, 14] = sale_record.zipcode_plus
        counter+=1
        ws.save()
      end


      # path = "#{Rails.root}/public/back_end_sale_comp/"
      # extension = "4"
      # session.drive.export_file(@file.id,extension,download_dest: "#{path}/#{@file.id}.xlsx")

      # save file name to database
      @BackEndSaleComp = BackEndSaleComp.new
      @BackEndSaleComp.user_id = @current_user.id
      @BackEndSaleComp.file = @file.id
      @BackEndSaleComp.save



      @file_temp = session.drive.copy_file(@file.id, {name: "#{@file.id}_temp"}, {})

      session.drive.batch do
        user_permission = {
            value: 'default',
            type: 'anyone',
            role: 'writer'
        }
        session.drive.create_permission(@file_temp.id, user_permission, fields: 'id')
      end
      @file = BackEndSaleComp.where('user_id = ?', @current_user).first
      # # dummy view of data
      # (1..ws.num_rows).each do |row|
      #   (1..ws.num_cols).each do |col|
      #     p ws[row, col]
      #   end
      # end
    else
      @file = BackEndSaleComp.where('user_id = ?', @current_user).first
      # put data to sheet
      ws = session.spreadsheet_by_key(@file.file).worksheets[0]
      counter=2
      sale_records.each do |sale_record|
        # if sale_record.id!=ws[counter, 1]
        #   ws.delete_rows(counter, 1)
        # end
        ws[counter, 1] = sale_record.id
        ws[counter, 2] = sale_record.is_sales_record
        ws[counter, 3] = sale_record.land_size_identifier
        ws[counter, 4] = sale_record.view_type
        ws[counter, 5] = sale_record.address1
        ws[counter, 6] = sale_record.city
        ws[counter, 7] = sale_record.state
        ws[counter, 8] = sale_record.land_size
        ws[counter, 9] = sale_record.price
        ws[counter, 10] = sale_record.cap_rate
        ws[counter, 11] = sale_record.latitude
        ws[counter, 12] = sale_record.longitude
        ws[counter, 13] = sale_record.zipcode
        ws[counter, 14] = sale_record.zipcode_plus
        counter+=1
        ws.save()
      end


      @file_temp = session.drive.copy_file(@file.file, {name: "#{@file.file}_temp"}, {})

      session.drive.batch do
        user_permission = {
            value: 'default',
            type: 'anyone',
            role: 'writer'
        }
        session.drive.create_permission(@file_temp.id, user_permission, fields: 'id')
      end
      # dummy view of data
      (1..ws.num_rows).each do |row|
        (1..ws.num_cols).each do |col|
          p ws[row, col]
        end
      end

    end

  end

  def create

    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    session.drive.delete_file(params[:id])
    @file = session.drive.copy_file("#{params[:temp]}", {name: params[:id]}, {})

    @BackEndSaleComp = BackEndSaleComp.where("user_id = ?",@current_user.id).first
    @BackEndSaleComp.update_attributes(:file => @file.id)

    session.drive.delete_file(params[:temp])
    ws = session.spreadsheet_by_key(@file.id).worksheets[0]

    sale_records = SaleRecord.where('user_id = ?', @current_user)
    counter=2
    sale_records.each do |sale_record|
      if sale_record.id!=counter-1
        ws[counter, 1] =  counter
        next
      end
      if SaleRecord.where(:id => ws[counter, 1]).present?
        @sale_record = SaleRecord.find_by(:id => ws[counter, 1])
        @sale_record.update_attributes(
            :is_sales_record => ws[counter, 2],
            :land_size_identifier => ws[counter, 3],
            :view_type => ws[counter, 4],
            :address1 =>  ws[counter, 5],
            :city => ws[counter, 6],
            :state => ws[counter, 7],
            :land_size => ws[counter, 8],
            :price => ws[counter, 9],
            :cap_rate => ws[counter, 10],
            :latitude => ws[counter, 11],
            :longitude => ws[counter, 12],
            :zipcode => ws[counter, 13],
            :zipcode_plus => ws[counter, 14]
        )
      end
      counter+=1
    end

    redirect_to root_url
  end
end
