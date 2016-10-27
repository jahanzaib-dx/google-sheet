class BackEndLeaseCompsController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  def index
    tenant_records = TenantRecord.where('user_id = ?', @current_user)

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("config.json")

    check = BackEndLeaseComp.where('user_id = ?', @current_user)
    if  check.count == 0
      @file = session.drive.copy_file('10KQmfFzqChd9-ihBwQj-aEbAjeJGOhe3PUl9MhZDMdw', {name: fileName}, {})

      # put data to sheet
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
      counter=2
      tenant_records.each do |tenant_record|
        # if tenant_record.id!=counter-1
        #   ws[counter, 1] =  counter
        #   next
        # end
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = tenant_record.company
        ws[counter, 3] = tenant_record.address1
        ws[counter, 4] = tenant_record.suite
        ws[counter, 5] = tenant_record.city
        ws[counter, 6] = tenant_record.state
        ws[counter, 7] = tenant_record.zipcode
        ws[counter, 8] = tenant_record.base_rent
        ws[counter, 9] = tenant_record.class_type
        ws[counter, 10] = tenant_record.comp_type
        ws[counter, 11] = tenant_record.contact
        ws[counter, 12] = tenant_record.contact_email
        ws[counter, 13] = tenant_record.contact_phone
        ws[counter, 14] = tenant_record.lease_type
        ws[counter, 15] = tenant_record.escalation
        ws[counter, 16] = tenant_record.free_rent
        ws[counter, 17] = tenant_record.industry_sic_code_id
        ws[counter, 18] = tenant_record.lease_commencement_date
        ws[counter, 19] = tenant_record.lease_term_months
        ws[counter, 20] = tenant_record.property_type
        ws[counter, 21] = tenant_record.size
        ws[counter, 22] = tenant_record.tenant_improvement
        ws[counter, 23] = tenant_record.tenant_ti_cost
        ws[counter, 24] = tenant_record.view_type
        ws[counter, 25] = tenant_record.comments
        ws[counter, 26] = tenant_record.property_name
        ws[counter, 27] = tenant_record.submarket
        ws[counter, 28] = tenant_record.industry_type
        counter+=1
        ws.save()
      end


      path = "#{Rails.root}/public/back_end_lease_comp/"
      extension = "4"
      session.drive.export_file(@file.id,extension,download_dest: "#{path}/#{@file.id}.xlsx")

      # save file name to database
      @BackEndLeaseComp = BackEndLeaseComp.new
      @BackEndLeaseComp.user_id = @current_user.id
      @BackEndLeaseComp.file = @file.id
      @BackEndLeaseComp.save



      @file_temp = session.drive.copy_file(@file.id, {name: "#{@file.id}_temp"}, {})

      session.drive.batch do
        user_permission = {
            value: 'default',
            type: 'anyone',
            role: 'writer'
        }
        session.drive.create_permission(@file_temp.id, user_permission, fields: 'id')
      end
      @file = BackEndLeaseComp.where('user_id = ?', @current_user).first
      # # dummy view of data
      # (1..ws.num_rows).each do |row|
      #   (1..ws.num_cols).each do |col|
      #     p ws[row, col]
      #   end
      # end
    else
      @file = BackEndLeaseComp.where('user_id = ?', @current_user).first
      # put data to sheet
      ws = session.spreadsheet_by_key(@file.file).worksheets[0]
      counter=2
      tenant_records.each do |tenant_record|
        # if tenant_record.id!=ws[counter, 1]
        #   ws.delete_rows(counter, 1)
        # end
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = tenant_record.company
        ws[counter, 3] = tenant_record.address1
        ws[counter, 4] = tenant_record.suite
        ws[counter, 5] = tenant_record.city
        ws[counter, 6] = tenant_record.state
        ws[counter, 7] = tenant_record.zipcode
        ws[counter, 8] = tenant_record.base_rent
        ws[counter, 9] = tenant_record.class_type
        ws[counter, 10] = tenant_record.comp_type
        ws[counter, 11] = tenant_record.contact
        ws[counter, 12] = tenant_record.contact_email
        ws[counter, 13] = tenant_record.contact_phone
        ws[counter, 14] = tenant_record.lease_type
        ws[counter, 15] = tenant_record.escalation
        ws[counter, 16] = tenant_record.free_rent
        ws[counter, 17] = tenant_record.industry_sic_code_id
        ws[counter, 18] = tenant_record.lease_commencement_date
        ws[counter, 19] = tenant_record.lease_term_months
        ws[counter, 20] = tenant_record.property_type
        ws[counter, 21] = tenant_record.size
        ws[counter, 22] = tenant_record.tenant_improvement
        ws[counter, 23] = tenant_record.tenant_ti_cost
        ws[counter, 24] = tenant_record.view_type
        ws[counter, 25] = tenant_record.comments
        ws[counter, 26] = tenant_record.property_name
        ws[counter, 27] = tenant_record.submarket
        ws[counter, 28] = tenant_record.industry_type
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

    @BackEndLeaseComp = BackEndLeaseComp.where("user_id = ?",@current_user.id).first
    @BackEndLeaseComp.update_attributes(:file => @file.id)

    session.drive.delete_file(params[:temp])
    # ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    #
    # tenant_records = TenantRecord.where('user_id = ?', @current_user)
    # counter=2
    # tenant_records.each do |tenant_record|
    #   if tenant_record.id!=counter-1
    #     ws[counter, 1] =  counter
    #     next
    #   end
    #   # tenant_record = TenantRecord.where('user_id = ? and id = ?', @current_user,tenant_record.id)
    #
    #   if TenantRecord.where(:id => ws[counter, 1]).present?
    #     @tenant_record = TenantRecord.find_by(:id => ws[counter, 1])
    #     @tenant_record.update(
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
    #     tenant_record = TenantRecord.new
    #     tenant_record.company = ws[counter, 2]
    #     tenant_record.address1 = ws[counter, 3]
    #     tenant_record.suite = ws[counter, 4]
    #     tenant_record.city = ws[counter, 5]
    #     tenant_record.state = ws[counter, 6]
    #     tenant_record.zipcode = ws[counter, 7]
    #     tenant_record.base_rent = ws[counter, 8]
    #     tenant_record.class_type = ws[counter, 9]
    #     tenant_record.comp_type = ws[counter, 10]
    #     tenant_record.contact = ws[counter, 11]
    #     tenant_record.contact_email = ws[counter, 12]
    #     tenant_record.contact_phone = ws[counter, 13]
    #     tenant_record.lease_type = ws[counter, 14]
    #     tenant_record.escalation = ws[counter, 15]
    #     tenant_record.free_rent = ws[counter, 16]
    #     tenant_record.industry_sic_code_id = ws[counter, 17]
    #     tenant_record.lease_commencement_date = ws[counter, 18]
    #     tenant_record.lease_term_months = ws[counter, 19]
    #     tenant_record.property_type = ws[counter, 20]
    #     tenant_record.size = ws[counter, 21]
    #     tenant_record.tenant_improvement = ws[counter, 22]
    #     tenant_record.tenant_ti_cost = ws[counter, 23]
    #     tenant_record.view_type = ws[counter, 24]
    #     tenant_record.comments = ws[counter, 25]
    #     tenant_record.property_name = ws[counter, 26]
    #     tenant_record.submarket = ws[counter, 27]
    #     tenant_record.industry_type = ws[counter, 28]
    #     tenant_record.save(validate: false)
    #   end
    #   counter+=1
    # end

    redirect_to root_url
  end
end
