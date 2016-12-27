class BackEndSaleCompsController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  def index
    sale_records = SaleRecord.where('user_id = ?', @current_user).order(:id)

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

    check = BackEndSaleComp.where('user_id = ?', @current_user)
    if  check.count == 0
      @file = session.drive.copy_file('1xPvNyWzcah6fbf_VlunbE_GDfMG1ufw3Gb2UeLa0MGo', {name: fileName}, {})

      # put data to sheet
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
      counter=2
      sale_records.each do |sale_record|
        ws[counter, 1] = sale_record.id
        ws[counter, 2] = '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = sale_record.view_type
        ws[counter, 4] = sale_record.address1
        ws[counter, 5] = sale_record.city
        ws[counter, 6] = sale_record.state
        ws[counter, 7] = sale_record.submarket
        ws[counter, 8] = sale_record.property_name
        ws[counter, 9] = sale_record.build_date
        ws[counter, 10] = sale_record.property_type
        ws[counter, 11] = sale_record.class_type
        ws[counter, 12] = sale_record.land_size
        ws[counter, 13] = sale_record.price
        ws[counter, 14] = sale_record.sold_date
        ws[counter, 15] = sale_record.cap_rate
        counter+=1
      end
      ws.save()

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
    else
      @file = BackEndSaleComp.where('user_id = ?', @current_user).first
      # put data to sheet
      ws = session.spreadsheet_by_key(@file.file).worksheets[0]
      max_rows = ws.num_rows
      counter=2
      sale_records.each do |sale_record|
        if sale_record.id != ws[counter,1] or ws[counter,1] == ''
          ws[counter, 1] = ''
          ws[counter, 2] = ''
          ws[counter, 3] = ''
          ws[counter, 4] = ''
          ws[counter, 5] = ''
          ws[counter, 6] = ''
          ws[counter, 7] = ''
          ws[counter, 8] = ''
          ws[counter, 9] = ''
          ws[counter, 10] = ''
          ws[counter, 11] = ''
          ws[counter, 12] = ''
          ws[counter, 13] = ''
          ws[counter, 14] = ''
          ws[counter, 15] = ''
          counter+=1
        end
        ws[counter, 1] = sale_record.id
        ws[counter, 2] = '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = sale_record.view_type
        ws[counter, 4] = sale_record.address1
        ws[counter, 5] = sale_record.city
        ws[counter, 6] = sale_record.state
        ws[counter, 7] = sale_record.submarket
        ws[counter, 8] = sale_record.property_name
        ws[counter, 9] = sale_record.build_date
        ws[counter, 10] = sale_record.property_type
        ws[counter, 11] = sale_record.class_type
        ws[counter, 12] = sale_record.land_size
        ws[counter, 13] = sale_record.price
        ws[counter, 14] = sale_record.sold_date
        ws[counter, 15] = sale_record.cap_rate
        counter+=1
      end
      if max_rows>=counter
        while counter<=max_rows
          ws[counter, 1] = ''
          ws[counter, 2] = ''
          ws[counter, 3] = ''
          ws[counter, 4] = ''
          ws[counter, 5] = ''
          ws[counter, 6] = ''
          ws[counter, 7] = ''
          ws[counter, 8] = ''
          ws[counter, 9] = ''
          ws[counter, 10] = ''
          ws[counter, 11] = ''
          ws[counter, 12] = ''
          ws[counter, 13] = ''
          ws[counter, 14] = ''
          ws[counter, 15] = ''
          counter+=1
        end
      end
      ws.save()
      @file_temp = session.drive.copy_file(@file.file, {name: "#{@file.file}_temp"}, {})
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
        :file => @file.file
    }
  end

  def create

    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    if !params[:temp].present?
      ws = session.spreadsheet_by_key(params[:id]).worksheets[0]
    else
      session.drive.delete_file(params[:id])
      @file = session.drive.copy_file("#{params[:temp]}", {name: params[:id]}, {})

      @BackEndSaleComp = BackEndSaleComp.where("user_id = ?",@current_user.id).first
      @BackEndSaleComp.update_attributes(:file => @file.id)

      session.drive.delete_file(params[:temp])
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    end
    sale_records = SaleRecord.where('user_id = ?', @current_user)
    counter=2
    ids= Array.new
    sale_records.each do |sale_record|
      # if sale_record.id!=counter-1
      #   ws[counter, 1] =  counter
      #   next
      # end
      if SaleRecord.where(:id => ws[counter, 1]).present?
        @sale_record = SaleRecord.find_by(:id => ws[counter, 1])
        @sale_record.update_attributes(
            # :image => ws[counter, 2],
            :view_type => ws[counter, 3],
            :address1 => ws[counter, 4],
            :city =>  ws[counter, 5],
            :state => ws[counter, 6],
            :submarket => ws[counter, 7],
            :property_name => ws[counter, 8],
            :build_date => ws[counter, 9],
            :property_type => ws[counter, 10],
            :class_type => ws[counter, 11],
            :land_size => ws[counter, 12],
            :price => ws[counter, 13],
            :sold_date => ws[counter, 14],
            :cap_rate => ws[counter, 15]
        )
      end
      if ws[counter, 1] != ''
        ids.push(ws[counter, 1])
      end
      counter+=1
    end
    deleted = ids.any? ? SaleRecord.where('id NOT IN (?) and user_id = ?',ids,@current_user) : SaleRecord.where('user_id = ?',@current_user)
    deleted.destroy_all
    redirect_to database_back_ends_path
  end

  def duplication
    sale_records = SaleRecord.duplicate_list(current_user.id)

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

    @file = session.drive.copy_file('1CcONE2zcYygchHXZQvaw5FnwShJT76T6xRL8OX1sbUI', {name: fileName}, {})

    # put data to sheet
    ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    counter=2
    sale_records.each do |sale_record|
      ws[counter, 1] = sale_record.id
      ws[counter, 2] = 'Keep'
      ws[counter, 3] = '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
      ws[counter, 4] = sale_record.view_type
      ws[counter, 5] = sale_record.address1
      ws[counter, 6] = sale_record.city
      ws[counter, 7] = sale_record.state
      ws[counter, 8] = sale_record.submarket
      ws[counter, 9] = sale_record.property_name
      ws[counter, 10] = sale_record.build_date
      ws[counter, 11] = sale_record.property_type
      ws[counter, 12] = sale_record.class_type
      ws[counter, 13] = sale_record.land_size
      ws[counter, 14] = sale_record.price
      ws[counter, 15] = sale_record.sold_date
      ws[counter, 16] = sale_record.cap_rate
      counter+=1
    end
    ws.save()

    @file_temp = session.drive.copy_file(@file.id, {name: "#{@file.id}_temp"}, {})

    session.drive.batch do
      user_permission = {
          value: 'default',
          type: 'anyone',
          role: 'writer'
      }
      session.drive.create_permission(@file_temp.id, user_permission, fields: 'id')
    end
    render :json => {
        :file_temp => @file_temp.id
    }

  end

  def delete_duplication
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    ws = session.spreadsheet_by_key(params[:id]).worksheets[0]
    sale_records = SaleRecord.where('user_id = ?', @current_user)
    counter=2
    ids= Array.new
    sale_records.each do |sale_record|
      # if sale_record.id!=counter-1
      #   ws[counter, 1] =  counter
      #   next
      # end
      if SaleRecord.where(:id => ws[counter, 1]).present?
        @sale_record = SaleRecord.find_by(:id => ws[counter, 1])
        @sale_record.update_attributes(
            # :image => ws[counter, 3],
            :view_type => ws[counter, 4],
            :address1 => ws[counter, 5],
            :city =>  ws[counter, 6],
            :state => ws[counter, 7],
            :submarket => ws[counter, 8],
            :property_name => ws[counter, 9],
            :build_date => ws[counter, 10],
            :property_type => ws[counter, 11],
            :class_type => ws[counter, 12],
            :land_size => ws[counter, 13],
            :price => ws[counter, 14],
            :sold_date => ws[counter, 15],
            :cap_rate => ws[counter, 16]
        )
      end
      if ws[counter,2] == 'Delete'
        ids.push(ws[counter, 1])
      end
      counter+=1
    end
    deleted = SaleRecord.where('id IN (?) and user_id = ?',ids,@current_user)
    deleted.destroy_all
    redirect_to database_back_ends_path
  end
end
