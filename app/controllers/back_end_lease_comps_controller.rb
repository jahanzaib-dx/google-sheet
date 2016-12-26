class BackEndLeaseCompsController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  def index
    tenant_records = TenantRecord.where('user_id = ?', @current_user).order(:id)

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

    check = BackEndLeaseComp.where('user_id = ?', @current_user)
    if  check.count == 0
      @file = session.drive.copy_file('1simT-7peFhoY-k9zrov3XYP4XpWJKPQRMz2sQYA5F1Y', {name: fileName}, {})

      # put data to sheet
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
      counter=2
      tenant_records.each do |tenant_record|
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = "=image('http://www.google.com/maps?cbll=#{tenant_record.latitude},#{tenant_record.longitude}&layer=c',2)"
        ws[counter, 3] = tenant_record.comp_type
        ws[counter, 4] = tenant_record.company
        ws[counter, 5] = tenant_record.industry_type
        ws[counter, 6] = tenant_record.address1
        ws[counter, 7] = tenant_record.suite
        ws[counter, 8] = tenant_record.city
        ws[counter, 9] = tenant_record.state
        ws[counter, 10] = tenant_record.submarket
        ws[counter, 11] = tenant_record.class_type
        ws[counter, 12] = tenant_record.property_type
        ws[counter, 13] = tenant_record.property_name
        ws[counter, 14] = tenant_record.lease_commencement_date
        ws[counter, 15] = tenant_record.lease_term_months
        ws[counter, 16] = tenant_record.free_rent
        ws[counter, 17] = tenant_record.size
        ws[counter, 18] = tenant_record.deal_type
        ws[counter, 19] = 'Lease Structure'
        ws[counter, 20] = tenant_record.base_rent
        counter+=1
      end
      ws.save()

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
    else
      @file = BackEndLeaseComp.where('user_id = ?', @current_user).first
      # put data to sheet
      ws = session.spreadsheet_by_key(@file.file).worksheets[0]

      # max_rows = ws.num_rows
      # i=2
      # while i<=max_rows
      #   if tenant_records.where('id = ?', ws[i,1]) && ws[i,1] != ''
      #     p ws[i,1]
      #   else
      #     p ws[i,1]
      #     max_rows-=1
      #   end
      #   i+=1
      #   p i
      #   p max_rows
      # end
      counter=2
      tenant_records.each do |tenant_record|
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = '=image("http://www.google.com/maps?cbll=#{tenant_record.latitude},#{tenant_record.longitude}&layer=c",2)'
        ws[counter, 3] = tenant_record.comp_type
        ws[counter, 4] = tenant_record.company
        ws[counter, 5] = tenant_record.industry_type
        ws[counter, 6] = tenant_record.address1
        ws[counter, 7] = tenant_record.suite
        ws[counter, 8] = tenant_record.city
        ws[counter, 9] = tenant_record.state
        ws[counter, 10] = tenant_record.submarket
        ws[counter, 11] = tenant_record.class_type
        ws[counter, 12] = tenant_record.property_type
        ws[counter, 13] = tenant_record.property_name
        ws[counter, 14] = tenant_record.lease_commencement_date
        ws[counter, 15] = tenant_record.lease_term_months
        ws[counter, 16] = tenant_record.free_rent
        ws[counter, 17] = tenant_record.size
        ws[counter, 18] = tenant_record.deal_type
        ws[counter, 19] = 'Lease Structure'
        ws[counter, 20] = tenant_record.base_rent
        counter+=1
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
      @BackEndLeaseComp = BackEndLeaseComp.where("user_id = ?",@current_user.id).first
      @BackEndLeaseComp.update_attributes(:file => @file.id)
      session.drive.delete_file(params[:temp])
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    end

    tenant_records = TenantRecord.where('user_id = ?', @current_user)
    counter=2
    ids= Array.new
    tenant_records.each do |tenant_record|
      if TenantRecord.where(:id => ws[counter, 1]).present?
        @tenant_record = TenantRecord.find_by(:id => ws[counter, 1])
        @tenant_record.update_attributes(
            # :image => ws[counter, 2],
            :comp_type => ws[counter, 3],
            :company => ws[counter, 4],
            :industry_type => ws[counter, 5],
            :address1 => ws[counter, 6],
            :suite => ws[counter, 7],
            :city => ws[counter, 8],
            :state => ws[counter, 9],
            :submarket => ws[counter, 10],
            :class_type => ws[counter, 11],
            :property_type => ws[counter, 12],
            :property_name => ws[counter, 13],
            :lease_commencement_date => ws[counter, 14],
            :lease_term_months => ws[counter, 15],
            :free_rent => ws[counter, 16],
            :size => ws[counter, 17],
            :deal_type => ws[counter, 18],
            :lease_structure => ws[counter, 19],
            :base_rent => ws[counter, 20]
        )
      end
      if ws[counter,1] != ''
        ids.push(ws[counter, 1])
      end
      counter+=1
    end
    deleted = ids.any? ? TenantRecord.where('id NOT IN (?) and user_id = ?',ids,@current_user) : TenantRecord.where('user_id = ?',@current_user)
    deleted.destroy_all
    redirect_to root_url
  end

  def duplication
   tenant_records = TenantRecord.duplicate_list(current_user.id)
   time = Time.now.getutc
   fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
   session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

     @file = session.drive.copy_file('12SnCrR6p2iMdGqKi05mL7TVj_-4CtV08rigwjA4rcP8', {name: fileName}, {})

     # put data to sheet
     ws = session.spreadsheet_by_key(@file.id).worksheets[0]
     counter=2
     tenant_records.each do |tenant_record|
       ws[counter, 1] = tenant_record.id
       ws[counter, 2] = 'Keep'
       # ws[counter, 3] = tenant_record.image
       ws[counter, 4] = tenant_record.comp_type
       ws[counter, 5] = tenant_record.company
       ws[counter, 6] = tenant_record.industry_type
       ws[counter, 7] = tenant_record.address1
       ws[counter, 8] = tenant_record.suite
       ws[counter, 9] = tenant_record.city
       ws[counter, 10] = tenant_record.state
       ws[counter, 11] = tenant_record.submarket
       ws[counter, 12] = tenant_record.class_type
       ws[counter, 13] = tenant_record.property_type
       ws[counter, 14] = tenant_record.property_name
       ws[counter, 15] = tenant_record.lease_commencement_date
       ws[counter, 16] = tenant_record.lease_term_months
       ws[counter, 17] = tenant_record.free_rent
       ws[counter, 18] = tenant_record.size
       ws[counter, 19] = tenant_record.deal_type
       ws[counter, 20] = 'Lease Structure'
       ws[counter, 21] = tenant_record.base_rent
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
    tenant_records = TenantRecord.where('user_id = ?', @current_user)
    counter=2
    ids= Array.new
    tenant_records.each do |tenant_record|
      if TenantRecord.where(:id => ws[counter, 1]).present?
        @tenant_record = TenantRecord.find_by(:id => ws[counter, 1])
        @tenant_record.update_attributes(
            # :image => ws[counter, 3],
            :comp_type => ws[counter, 4],
            :company => ws[counter, 5],
            :industry_type => ws[counter, 6],
            :address1 => ws[counter, 7],
            :suite => ws[counter, 8],
            :city => ws[counter, 9],
            :state => ws[counter, 10],
            :submarket => ws[counter, 11],
            :class_type => ws[counter, 12],
            :property_type => ws[counter, 13],
            :property_name => ws[counter, 14],
            :lease_commencement_date => ws[counter, 15],
            :lease_term_months => ws[counter, 16],
            :free_rent => ws[counter, 17],
            :size => ws[counter, 18],
            :deal_type => ws[counter, 19],
            :lease_structure => ws[counter, 20],
            :base_rent => ws[counter, 21]
        )
      end
      if ws[counter,2] == 'Delete'
        ids.push(ws[counter, 1])
      end
      counter+=1
    end
    deleted = TenantRecord.where('id IN (?) and user_id = ?',ids,@current_user)
    deleted.destroy_all
    redirect_to root_url
  end
end
