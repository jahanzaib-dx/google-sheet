class BackEndSaleCompsController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  include GoogleGeocoder

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
        ws[counter, 2] = (sale_record.main_image_file_name.present?) ? sale_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = sale_record.view_type
        ws[counter, 4] = sale_record.address1
        ws[counter, 5] = sale_record.city
        ws[counter, 6] = sale_record.state
        ws[counter, 7] = sale_record.country
        ws[counter, 8] = sale_record.submarket
        ws[counter, 9] = sale_record.property_name
        ws[counter, 10] = sale_record.build_date
        ws[counter, 11] = sale_record.property_type
        ws[counter, 12] = sale_record.class_type
        ws[counter, 13] = sale_record.land_size
        ws[counter, 14] = sale_record.price
        ws[counter, 15] = sale_record.sold_date
        ws[counter, 16] = sale_record.cap_rate
        ws[counter, 17] = (sale_record.is_sales_record) ? "Land Record":"Building Record"
        counter+=1
      end
      if counter>2
        counter-=1
      end
      if ws.max_rows>counter
        ws.delete_rows(counter+1,ws.max_rows-counter)
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

      @file_temp = session.drive.copy_file(@file.id, {name: "#{@current_user.id}_temp"}, {})

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
      counter=2

      while ws[counter,1]!=""
        if !sale_records.find_by_id(ws[counter,1]).present?
          ws.delete_rows(counter,1)
        end
        counter+=1
      end

      counter=2
      if ws.max_rows<sale_records.count
        ws.insert_rows(ws.max_rows,tenant_records.count-ws.max_rows)
      end

      sale_records.each do |sale_record|
        ws[counter, 1] = sale_record.id
        ws[counter, 2] = (sale_record.main_image_file_name.present?) ? sale_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = sale_record.view_type
        ws[counter, 4] = sale_record.address1
        ws[counter, 5] = sale_record.city
        ws[counter, 6] = sale_record.state
        ws[counter, 7] = sale_record.country
        ws[counter, 8] = sale_record.submarket
        ws[counter, 9] = sale_record.property_name
        ws[counter, 10] = sale_record.build_date
        ws[counter, 11] = sale_record.property_type
        ws[counter, 12] = sale_record.class_type
        ws[counter, 13] = sale_record.land_size
        ws[counter, 14] = sale_record.price
        ws[counter, 15] = sale_record.sold_date
        ws[counter, 16] = sale_record.cap_rate
        ws[counter, 17] = (sale_record.is_sales_record) ? "Land Record":"Building Record"
        counter+=1
      end
      if counter>2
        counter-=1
      end
      if ws.max_rows>counter
        ws.delete_rows(counter+1,ws.max_rows-counter)
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
    @is_potential_dupes = SaleRecord.duplicate_list(current_user.id).count
    render :json => {
        :file_temp => @file_temp.id,
        :file => @file.file,
        :is_potential_dupes => @is_potential_dupes
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
      # while ws[counter,1] != sale_record.id.to_s
      #   counter+=1
      # end
      if SaleRecord.where(:id => ws[counter, 1]).present?
        @sale_record = SaleRecord.find_by(:id => ws[counter, 1])
        @sale_record.update_attributes(
            :main_image_file_name => ws.input_value(counter, 2),
            :view_type => ws[counter, 3],
            :address1 => ws[counter, 4],
            :city =>  ws[counter, 5],
            :state => ws[counter, 6],
            :country => ws[counter, 7],
            :submarket => ws[counter, 8],
            :property_name => ws[counter, 9],
            :build_date => ws[counter, 10],
            :property_type => ws[counter, 11],
            :class_type => ws[counter, 12],
            :land_size => ws[counter, 13],
            :price => ws[counter, 14],
            :sold_date => ws[counter, 15],
            :cap_rate => ws[counter, 16],
            :is_sales_record => (ws[counter, 17]=='Land Record') ? 'TRUE' : 'False'
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
      ws[counter, 3] = (sale_record.main_image_file_name.present?) ? sale_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
      ws[counter, 4] = sale_record.view_type
      ws[counter, 5] = sale_record.address1
      ws[counter, 6] = sale_record.city
      ws[counter, 7] = sale_record.state
      ws[counter, 8] = sale_record.country
      ws[counter, 9] = sale_record.submarket
      ws[counter, 10] = sale_record.property_name
      ws[counter, 11] = sale_record.build_date
      ws[counter, 12] = sale_record.property_type
      ws[counter, 13] = sale_record.class_type
      ws[counter, 14] = sale_record.land_size
      ws[counter, 15] = sale_record.price
      ws[counter, 16] = sale_record.sold_date
      ws[counter, 17] = sale_record.cap_rate
      ws[counter, 18] = (sale_record.is_sales_record) ? "Land Record":"Building Record"
      counter+=1
    end
    ws.save()

    @file_temp = session.drive.copy_file(@file.id, {name: "#{@current_user.id}_temp"}, {})

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
            :country => ws[counter, 8],
            :submarket => ws[counter, 9],
            :property_name => ws[counter, 10],
            :build_date => ws[counter, 11],
            :property_type => ws[counter, 12],
            :class_type => ws[counter, 13],
            :land_size => ws[counter, 14],
            :price => ws[counter, 15],
            :sold_date => ws[counter, 16],
            :cap_rate => ws[counter, 17],
            :is_sales_record => (ws[counter, 18]=='Land Record') ? 'TRUE' : 'False'
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

  def validate_spreadsheet
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    ws = session.spreadsheet_by_key(params[:temp]).worksheets[0]

    sale_records = SaleRecord.where('user_id = ?', @current_user)
    error_string=""
    counter=2
    if params[:id].present?
      sale_records.each do |sale_record|
        if SaleRecord.where(:id => ws[counter, 1]).present?
          @sale_record = SaleRecord.find_by(:id => ws[counter, 1])
          error_string += (ws[counter, 3] == '')? "</br>Cell no. C#{counter} is required" : ""
          @sale_record.address1 = ws[counter, 4]
          @sale_record.city = ws[counter, 5]
          @sale_record.state = ws[counter, 6]
          result = validate_address_google(@sale_record,true)
          if result.has_key? :errors
            error_string += (result[:errors][:geocode_info].to_s != '') ? "</br>Cell no. D#{counter} "+result[:errors][:geocode_info].to_s : ""
          end
          error_string += (ws[counter, 4] == '')? "</br>Cell no. D#{counter} is required" : ""
          error_string += (ws[counter, 5] == '')? "</br>Cell no. E#{counter} is required" : ""
          error_string += (ws[counter, 6] == '')? "</br>Cell no. F#{counter} is required" : ""
          error_string += (ws[counter, 7] == '')? "</br>Cell no. G#{counter} is required" : ""
          error_string += (ws[counter, 8] == '')? "</br>Cell no. H#{counter} is required" : ""
          error_string += (ws[counter, 10] == '' and !@sale_record.is_sales_record )? "</br>Cell no. J#{counter} is required" : ""
          error_string += (ws[counter, 11] == '' and !@sale_record.is_sales_record)? "</br>Cell no. K#{counter} is required" : ""
          error_string += (ws[counter, 12] == '' and !@sale_record.is_sales_record)? "</br>Cell no. L#{counter} is required" : ""
          error_string += (ws[counter, 13] == '')? "</br>Cell no. M#{counter} is required" : ""
          error_string += (ws[counter, 14] == '')? "</br>Cell no. N#{counter} is required" : ""
          error_string += (ws[counter, 15] == '')? "</br>Cell no. O#{counter} is required" : ""
          error_string += (ws[counter, 16] == '')? "</br>Cell no. P#{counter} is required" : ""
          error_string += (ws[counter, 17] == '')? "</br>Cell no. Q#{counter} is required" : ""
        end
        counter+=1
      end
    else

      sale_records.each do |sale_record|
        if SaleRecord.where(:id => ws[counter, 1]).present?
          @sale_record = SaleRecord.find_by(:id => ws[counter, 1])
          error_string += (ws[counter, 4] == '')? "</br>Cell no. D#{counter} is required" : ""
          @sale_record.address1 = ws[counter, 5]
          @sale_record.city = ws[counter, 6]
          @sale_record.state = ws[counter, 7]
          result = validate_address_google(@sale_record,true)
          p result.inspect
          if result.has_key? :errors
            error_string += (result[:errors][:geocode_info].to_s != '') ? "</br>Cell no. D#{counter} "+result[:errors][:geocode_info].to_s : ""
          end
          error_string += (ws[counter, 5] == '')? "</br>Cell no. E#{counter} is required" : ""
          error_string += (ws[counter, 6] == '')? "</br>Cell no. F#{counter} is required" : ""
          error_string += (ws[counter, 7] == '')? "</br>Cell no. G#{counter} is required" : ""
          error_string += (ws[counter, 8] == '')? "</br>Cell no. H#{counter} is required" : ""
          error_string += (ws[counter, 9] == '')? "</br>Cell no. I#{counter} is required" : ""
          error_string += (ws[counter, 11] == '' and !@sale_record.is_sales_record )? "</br>Cell no. K#{counter} is required" : ""
          error_string += (ws[counter, 12] == '' and !@sale_record.is_sales_record )? "</br>Cell no. L#{counter} is required" : ""
          error_string += (ws[counter, 13] == '' and !@sale_record.is_sales_record )? "</br>Cell no. M#{counter} is required" : ""
          error_string += (ws[counter, 14] == '')? "</br>Cell no. N#{counter} is required" : ""
          error_string += (ws[counter, 15] == '')? "</br>Cell no. O#{counter} is required" : ""
          error_string += (ws[counter, 16] == '')? "</br>Cell no. P#{counter} is required" : ""
          error_string += (ws[counter, 17] == '')? "</br>Cell no. Q#{counter} is required" : ""
          error_string += (ws[counter, 18] == '')? "</br>Cell no. R#{counter} is required" : ""
        end
        counter+=1
      end
    end

    delete_url = (params[:id].present?)? "/back_end_sale_comps/create/#{params[:id]}/#{params[:temp]}" : "/back_end_sale_comps/delete_duplication/#{params[:temp]}"
    if error_string==''
      render json:{
          flag: 'ok',
          url: delete_url
      }
    else
      render json:{
          error_string: error_string
      }
    end
  end
end
