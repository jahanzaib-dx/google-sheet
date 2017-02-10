class BackEndLeaseCompsController < ApplicationController
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  include GoogleGeocoder

  def index

    tenant_records = TenantRecord.where('user_id = ?', @current_user).order(:id)
    if TenantRecord.max_stepped_rent_by_user(current_user.id).first!=nil
      stepped_rent_count = TenantRecord.max_stepped_rent_by_user(current_user.id).first.countof
    else
      stepped_rent_count=0
    end

    time = Time.now.getutc
    fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")


    check = BackEndLeaseComp.where('user_id = ?', @current_user)
    if  check.count == 0
      @file = session.drive.copy_file('1simT-7peFhoY-k9zrov3XYP4XpWJKPQRMz2sQYA5F1Y', {name: fileName}, {})

      # put data to sheet
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
      counter=2
      i=1
      stepped_rent_col_head=27
      while i <= stepped_rent_count  do
        ws[1,stepped_rent_col_head] = "Step #{i} Cost Per SF"
        ws[1,stepped_rent_col_head+1] = "# of Months"
        i +=1
        stepped_rent_col_head+=2
      end
      tenant_records.each do |tenant_record|
        stepped_rent_col=27
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = (tenant_record.main_image_file_name.present?) ? tenant_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{tenant_record.latitude},#{tenant_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = tenant_record.comp_view_type
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
        ws[counter, 19] = (tenant_record.lease_structure.present?) ?  tenant_record.lease_structure : 'Full Service'
        ws[counter, 20] = tenant_record.base_rent
        ws[counter, 21] = tenant_record.tenant_improvement
        ws[counter, 22] = tenant_record.additional_tenant_cost
        ws[counter, 23] = tenant_record.additional_ll_allowance
        ws[counter, 24] = tenant_record.escalation
        ws[counter, 25] = tenant_record.fixed_escalation
        ws[counter, 26] = tenant_record.is_stepped_rent
        tenant_record.stepped_rents.each do |sr|
          ws[counter, stepped_rent_col] = sr.cost_per_month
          ws[counter, stepped_rent_col+1] = sr.months
          stepped_rent_col+=2
        end
        counter+=1
      end
      if counter>2
        counter-=1
      end
      if ws.max_rows>counter
        ws.delete_rows(counter+1,ws.max_rows-counter)
      end
      ws.save()

      # save file name to database
      @BackEndLeaseComp = BackEndLeaseComp.new
      @BackEndLeaseComp.user_id = @current_user.id
      @BackEndLeaseComp.file = @file.id
      @BackEndLeaseComp.save

      @file_temp = session.drive.copy_file(@file.id, {name: "#{@current_user.id}_temp"}, {})

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
      counter=2
      i=1
      stepped_rent_col_head=27
      while i <= stepped_rent_count  do
        ws[1,stepped_rent_col_head] = "Step #{i} Cost Per SF"
        ws[1,stepped_rent_col_head+1] = "# of Months"
        i +=1
        stepped_rent_col_head+=2
      end

      while ws[counter,1]!=""
        if !tenant_records.find_by_id(ws[counter,1]).present?
          ws.delete_rows(counter,1)
        end
        counter+=1
      end
      counter=2
      if ws.max_rows<tenant_records.count
        ws.insert_rows(ws.max_rows,tenant_records.count-ws.max_rows)
      end
      tenant_records.each do |tenant_record|
        stepped_rent_col=27
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = (tenant_record.main_image_file_name.present?) ? tenant_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{tenant_record.latitude},#{tenant_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = tenant_record.comp_view_type
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
        ws[counter, 19] = (tenant_record.lease_structure.present?) ?  tenant_record.lease_structure : 'Full Service'
        ws[counter, 20] = tenant_record.base_rent
        ws[counter, 21] = tenant_record.tenant_improvement
        ws[counter, 22] = tenant_record.additional_tenant_cost
        ws[counter, 23] = tenant_record.additional_ll_allowance
        ws[counter, 24] = tenant_record.escalation
        ws[counter, 25] = tenant_record.fixed_escalation
        ws[counter, 26] = tenant_record.is_stepped_rent
        tenant_record.stepped_rents.each do |sr|
          ws[counter, stepped_rent_col] = sr.cost_per_month
          ws[counter, stepped_rent_col+1] = sr.months
          stepped_rent_col+=2
        end
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
    @is_potential_dupes = TenantRecord.duplicate_list(current_user.id).count
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
      @BackEndLeaseComp = BackEndLeaseComp.where("user_id = ?",@current_user.id).first
      @BackEndLeaseComp.update_attributes(:file => @file.id)
      session.drive.delete_file(params[:temp])
      ws = session.spreadsheet_by_key(@file.id).worksheets[0]
    end

    tenant_records = TenantRecord.where('user_id = ?', @current_user)
    counter=2
    ids= Array.new
    tenant_records.each do |tenant_record|
      # while ws[counter,1] != tenant_record.id.to_s
      #   counter+=1
      # end
      stepped_rent_col=27

      if TenantRecord.where(:id => ws[counter, 1]).present?
        @tenant_record = TenantRecord.find_by(:id => ws[counter, 1])
        stepped_rent_values={}
        @tenant_record.stepped_rents.each.map do |sr|
          stepped_rent_values[sr.id]={
                :id => sr.id,
                :cost_per_month => ws[counter,stepped_rent_col],
                :months => ws[counter,stepped_rent_col+1]
              }
          stepped_rent_col+=2
        end
        @tenant_record.update_attributes(
            :main_image_file_name => ws.input_value(counter, 2),
            :comp_view_type => ws[counter, 3],
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
            :base_rent => ws[counter, 20],
            :tenant_improvement => ws[counter, 21],
            :additional_tenant_cost => ws[counter, 22],
            :additional_ll_allowance => ws[counter, 23],
            :escalation => ws[counter, 24],
            :fixed_escalation => ws[counter, 25],
            :is_stepped_rent => ws[counter, 26],
            :stepped_rents_attributes => stepped_rent_values
        )
        geocode_setup(@tenant_record)
      end
      if ws[counter,1] != ''
        ids.push(ws[counter, 1])
      end
      counter+=1
    end
    deleted = ids.any? ? TenantRecord.where('id NOT IN (?) and user_id = ?',ids,@current_user) : TenantRecord.where('user_id = ?',@current_user)
    deleted.destroy_all
    redirect_to database_back_ends_path
  end

  def duplication
   tenant_records = TenantRecord.duplicate_list(current_user.id)
   if TenantRecord.max_stepped_rent_by_user(current_user.id).first!=nil
     stepped_rent_count = TenantRecord.max_stepped_rent_by_user(current_user.id).first.countof
   else
     stepped_rent_count=0
   end

   time = Time.now.getutc
   fileName = Digest::SHA1.hexdigest("#{time}#{@current_user}")
   session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")

     @file = session.drive.copy_file('12SnCrR6p2iMdGqKi05mL7TVj_-4CtV08rigwjA4rcP8', {name: fileName}, {})

     # put data to sheet
     ws = session.spreadsheet_by_key(@file.id).worksheets[0]
     counter=2
     i=1
     stepped_rent_col_head=28
     while i <= stepped_rent_count  do
       ws[1,stepped_rent_col_head] = "Step #{i} Cost Per SF"
       ws[1,stepped_rent_col_head+1] = "# of Months"
       i +=1
       stepped_rent_col_head+=2
     end
     tenant_records.each do |tenant_record|
       stepped_rent_col=28
       ws[counter, 1] = tenant_record.id
       ws[counter, 2] = 'Keep'
       ws[counter, 3] = (tenant_record.main_image_file_name.present?) ? tenant_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{tenant_record.latitude},#{tenant_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
       ws[counter, 4] = tenant_record.comp_view_type
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
       ws[counter, 20] = (tenant_record.lease_structure.present?) ?  tenant_record.lease_structure : 'Full Service'
       ws[counter, 21] = tenant_record.base_rent
       ws[counter, 22] = tenant_record.tenant_improvement
       ws[counter, 23] = tenant_record.additional_tenant_cost
       ws[counter, 24] = tenant_record.additional_ll_allowance
       ws[counter, 25] = tenant_record.escalation
       ws[counter, 26] = tenant_record.fixed_escalation
       ws[counter, 27] = tenant_record.is_stepped_rent
       tenant_record.stepped_rents.each do |sr|
         ws[counter, stepped_rent_col] = sr.cost_per_month
         ws[counter, stepped_rent_col+1] = sr.months
         stepped_rent_col+=2
       end
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
    tenant_records = TenantRecord.where('user_id = ?', @current_user)
    counter=2
    ids= Array.new
    tenant_records.each do |tenant_record|
      if TenantRecord.where(:id => ws[counter, 1]).present?
        stepped_rent_col=28
        @tenant_record = TenantRecord.find_by(:id => ws[counter, 1])
        stepped_rent_values={}
        @tenant_record.stepped_rents.each.map do |sr|
          stepped_rent_values[sr.id]={
              :id => sr.id,
              :cost_per_month => ws[counter,stepped_rent_col],
              :months => ws[counter,stepped_rent_col+1]
          }
          stepped_rent_col+=2
        end
        @tenant_record.update_attributes(
            # :image => ws[counter, 3],
            :comp_view_type => ws[counter, 4],
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
            :base_rent => ws[counter, 21],
            :tenant_improvement => ws[counter, 22],
            :additional_tenant_cost => ws[counter, 23],
            :additional_ll_allowance => ws[counter, 24],
            :escalation => ws[counter, 25],
            :fixed_escalation => ws[counter, 26],
            :is_stepped_rent => ws[counter, 27],
            :stepped_rents_attributes => stepped_rent_values
        )
      end
      if ws[counter,2] == 'Delete'
        ids.push(ws[counter, 1])
      end
      counter+=1
    end
    deleted = TenantRecord.where('id IN (?) and user_id = ?',ids,@current_user)
    deleted.destroy_all
    redirect_to database_back_ends_path
  end

  def validate_spreadsheet
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    ws = session.spreadsheet_by_key(params[:temp]).worksheets[0]

    tenant_records = TenantRecord.where('user_id = ?', @current_user)
    error_string=""
    counter=2
    if params[:id].present?
      tenant_records.each do |tenant_record|
        # while ws[counter,1] != tenant_record.id.to_s
        #   counter+=1
        # end
        if TenantRecord.where(:id => ws[counter, 1]).present?
          @tenant_record = TenantRecord.find_by(:id => ws[counter, 1])
          error_string += (ws[counter, 3] == '')? "</br>Cell no. C#{counter} is required" : ""
          error_string += (ws[counter, 4] == '')? "</br>Cell no. D#{counter} is required" : ""
          error_string += (ws[counter, 5] == '')? "</br>Cell no. E#{counter} is required" : ""
          @tenant_record.address1 = ws[counter, 6]
          @tenant_record.city = ws[counter, 8]
          @tenant_record.state = ws[counter, 9]
          result = validate_address_google(@tenant_record,true)
          if result.has_key? :errors
            error_string += (result[:errors][:geocode_info].to_s != '') ? "</br>Cell no. F#{counter} "+result[:errors][:geocode_info].to_s : ""
          end
          error_string += (ws[counter, 6] == '')? "</br>Cell no. F#{counter} is required" : ""
          # error_string += (ws[counter, 7] == '')? "</br>Cell no. G#{counter} is required" : ""
          error_string += (ws[counter, 8] == '')? "</br>Cell no. H#{counter} is required" : ""
          error_string += (ws[counter, 9] == '')? "</br>Cell no. I#{counter} is required" : ""
          error_string += (ws[counter, 10] == '')? "</br>Cell no. J#{counter} is required" : ""
          error_string += (ws[counter, 11] == '')? "</br>Cell no. K#{counter} is required" : ""
          error_string += (ws[counter, 12] == '')? "</br>Cell no. L#{counter} is required" : ""
          error_string += (ws[counter, 14] == '')? "</br>Cell no. N#{counter} is required" : ""
          error_string += (ws[counter, 15] == '')? "</br>Cell no. O#{counter} is required" : ""
          error_string += (ws[counter, 17] == '')? "</br>Cell no. Q#{counter} is required" : ""
          error_string += (ws[counter, 18] == '')? "</br>Cell no. R#{counter} is required" : ""
          error_string += (ws[counter, 19] == '')? "</br>Cell no. S#{counter} is required" : ""
          error_string += (ws[counter, 20] == '')? "</br>Cell no. T#{counter} is required" : ""
          error_string += (
              (ws[counter, 24] == ''  || ws[counter, 24] == "0") &&
              (ws[counter, 25] == '' || ws[counter, 25] == "0") &&
              (ws[counter, 26] == '' || ws[counter, 26] == 'FALSE')
          )? "</br>Cell no. X#{counter}, Y#{counter}  and Z#{counter} are empty or false. One of them must be filled." : ""
        end
        counter+=1
      end
    else
      error_string='<br>'
      tenant_records.each do |tenant_record|
        # while ws[counter,1] != tenant_record.id.to_s
        #   counter+=1
        # end
        if TenantRecord.where(:id => ws[counter, 1]).present? and ws[counter,2] == 'Keep'
          @tenant_record = TenantRecord.find_by(:id => ws[counter, 1])
          error_string += (ws[counter, 4] == '')? "</br>Cell no. D#{counter} is required" : ""
          error_string += (ws[counter, 5] == '')? "</br>Cell no. E#{counter} is required" : ""
          error_string += (ws[counter, 6] == '')? "</br>Cell no. F#{counter} is required" : ""
          @tenant_record.address1 = ws[counter, 7]
          @tenant_record.city = ws[counter, 9]
          @tenant_record.state = ws[counter, 10]
          result = validate_address_google(@tenant_record,true)

          if result.has_key? :coords
            trec.latitude = result[:coords][:latitude]
            trec.longitude = result[:coords][:longitude]
          end

          if result.has_key? :updates
            trec.latitude = result[:updates][:latitude]
            trec.longitude = result[:updates][:longitude]
            trec.zipcode = result[:updates][:zipcode]
          end

          if result.has_key? :errors and !result.has_key? :coords and result.has_key? :updates
            error_string += (result[:errors][:geocode_info].to_s != '') ? "</br>Cell no. G#{counter} "+result[:errors][:geocode_info].to_s : ""
          end
          error_string += (ws[counter, 7] == '')? "</br>Cell no. G#{counter} is required" : ""
          # error_string += (ws[counter, 8] == '')? "</br>Cell no. H#{counter} is required" : ""
          error_string += (ws[counter, 9] == '')? "</br>Cell no. I#{counter} is required" : ""
          error_string += (ws[counter, 10] == '')? "</br>Cell no. J#{counter} is required" : ""
          error_string += (ws[counter, 11] == '')? "</br>Cell no. K#{counter} is required" : ""
          error_string += (ws[counter, 12] == '')? "</br>Cell no. L#{counter} is required" : ""
          error_string += (ws[counter, 13] == '')? "</br>Cell no. M#{counter} is required" : ""
          error_string += (ws[counter, 15] == '')? "</br>Cell no. O#{counter} is required" : ""
          error_string += (ws[counter, 16] == '')? "</br>Cell no. P#{counter} is required" : ""
          error_string += (ws[counter, 18] == '')? "</br>Cell no. R#{counter} is required" : ""
          error_string += (ws[counter, 19] == '')? "</br>Cell no. S#{counter} is required" : ""
          error_string += (ws[counter, 20] == '')? "</br>Cell no. T#{counter} is required" : ""
          error_string += (ws[counter, 21] == '')? "</br>Cell no. U#{counter} is required" : ""
          error_string += (
              (ws[counter, 25] == ''  || ws[counter, 25] == "0") &&
              (ws[counter, 26] == '' || ws[counter, 26] == "0") &&
              (ws[counter, 27] == '' || ws[counter, 27] == 'FALSE')
          )? "</br>Cell no. Y#{counter}, Z#{counter}  and AA#{counter} are empty or false. One of them must be filled." : ""
        end
        counter+=1
      end
    end
    delete_url = (params[:id].present?)? "/back_end_lease_comps/create/#{params[:id]}/#{params[:temp]}" : "/back_end_lease_comps/delete_duplication/#{params[:temp]}";
    if error_string=='' || error_string=='<br>'
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

  def geocode_setup(trec)
    result = validate_address_google(trec, true)
    if result.has_key? :updates
      @tenant_record.latitude = result[:updates][:latitude]
      @tenant_record.longitude = result[:updates][:longitude]
      @tenant_record.zipcode = result[:updates][:zipcode]
      @tenant_record.address1 = result[:updates][:address1]
      @tenant_record.city = result[:updates][:city]
      @tenant_record.state = result[:updates][:state]
      @tenant_record.save
    end
  end

end
