class BackEndSaleCompsController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  def index
    sale_records = SaleRecord.where('user_id = ?', @current_user)

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("config.json")

    check = BackEndSaleComp.where('user_id = ?', @current_user)
    if  check.count == 0
      @file = session.drive.copy_file('1Gc-2YU8anJma16JsWYIk6-Ym6gsq_kwvLqyOxBfD8R0', {name: fileName}, {})

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

    session = GoogleDrive::Session.from_config("config.json")
    session.drive.delete_file(params[:id])
    @file = session.drive.copy_file("#{params[:temp]}", {name: params[:id]}, {})

    @BackEndSaleComp = BackEndSaleComp.where("user_id = ?",@current_user.id).first
    @BackEndSaleComp.update_attributes(:file => @file.id)

    session.drive.delete_file(params[:temp])
    # ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    #
    # sale_records = SaleRecord.where('user_id = ?', @current_user)
    # counter=2
    # sale_records.each do |sale_record|
    #   if sale_record.id!=counter-1
    #     ws[counter, 1] =  counter
    #     next
    #   end
    #   # sale_record = SaleRecord.where('user_id = ? and id = ?', @current_user,sale_record.id)
    #
    #   if SaleRecord.where(:id => ws[counter, 1]).present?
    #     @sale_record = SaleRecord.find_by(:id => ws[counter, 1])
    #     @sale_record.update(
    #         :company => ws[counter, 2],
    #         :address1 => ws[counter, 3],
    #         :suite => ws[counter, 4],
    #         :city => ws[counter, 5],
    #         :state => ws[counter, 6],
    #         :zipcode => ws[counter, 7],
    #         :base_rent => ws[counter, 8],
    #         :class_type => ws[counter, 9],
    #         :comp_type => ws[counter, 10],
    #         :contact => ws[counter, 11],
    #         :contact_email => ws[counter, 12],
    #         :contact_phone => ws[counter, 13],
    #         :lease_type => ws[counter, 14],
    #         :escalation => ws[counter, 15],
    #         :free_rent => ws[counter, 16],
    #         :industry_sic_code_id => ws[counter, 17],
    #         :lease_commencement_date => ws[counter, 18],
    #         :lease_term_months => ws[counter, 19],
    #         :property_type => ws[counter, 20],
    #         :size => ws[counter, 21],
    #         :tenant_improvement => ws[counter, 22],
    #         :tenant_ti_cost => ws[counter, 23],
    #         :view_type => ws[counter, 24],
    #         :comments => ws[counter, 25],
    #         :property_name => ws[counter, 26],
    #         :submarket => ws[counter, 27],
    #         :industry_type => ws[counter, 28]
    #     )
    #
    #   else
    #     sale_record = SaleRecord.new
    #     sale_record.company = ws[counter, 2]
    #     sale_record.address1 = ws[counter, 3]
    #     sale_record.suite = ws[counter, 4]
    #     sale_record.city = ws[counter, 5]
    #     sale_record.state = ws[counter, 6]
    #     sale_record.zipcode = ws[counter, 7]
    #     sale_record.base_rent = ws[counter, 8]
    #     sale_record.class_type = ws[counter, 9]
    #     sale_record.comp_type = ws[counter, 10]
    #     sale_record.contact = ws[counter, 11]
    #     sale_record.contact_email = ws[counter, 12]
    #     sale_record.contact_phone = ws[counter, 13]
    #     sale_record.lease_type = ws[counter, 14]
    #     sale_record.escalation = ws[counter, 15]
    #     sale_record.free_rent = ws[counter, 16]
    #     sale_record.industry_sic_code_id = ws[counter, 17]
    #     sale_record.lease_commencement_date = ws[counter, 18]
    #     sale_record.lease_term_months = ws[counter, 19]
    #     sale_record.property_type = ws[counter, 20]
    #     sale_record.size = ws[counter, 21]
    #     sale_record.tenant_improvement = ws[counter, 22]
    #     sale_record.tenant_ti_cost = ws[counter, 23]
    #     sale_record.view_type = ws[counter, 24]
    #     sale_record.comments = ws[counter, 25]
    #     sale_record.property_name = ws[counter, 26]
    #     sale_record.submarket = ws[counter, 27]
    #     sale_record.industry_type = ws[counter, 28]
    #     sale_record.save(validate: false)
    #   end
    #   counter+=1
    # end

    redirect_to root_url
  end
end
