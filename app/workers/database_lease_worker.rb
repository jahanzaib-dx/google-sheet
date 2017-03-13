class DatabaseLeaseWorker
  include Sidekiq::Worker
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  include GoogleGeocoder
  sidekiq_options queue: "high"

  def perform(file_temp,id)
    tenant_records = TenantRecord.where('user_id = ?', id).order(:id)
    custom_headers = TenantRecord.custom_field_headers(id)
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    if TenantRecord.max_stepped_rent_by_user(id).first!=nil
      stepped_rent_count = TenantRecord.max_stepped_rent_by_user(id).first.countof
    else
      stepped_rent_count=0
    end
      ws = session.spreadsheet_by_key(file_temp).worksheets[0]
      counter=2
      i=1
      stepped_rent_col_head=29
      while i <= stepped_rent_count  do
        ws[1,stepped_rent_col_head] = "Step #{i} Cost Per SF"
        ws[1,stepped_rent_col_head+1] = "# of Months"
        i +=1
        stepped_rent_col_head+=2
      end
      custom_headers_col_head = stepped_rent_col_head
      custom_headers.each do |keys|
        ws[1,custom_headers_col_head]= keys.header
        custom_headers_col_head+=1
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
        stepped_rent_col=29
        ws[counter, 1] = tenant_record.id
        ws[counter, 2] = (tenant_record.main_image_file_name.present?) ? tenant_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{tenant_record.latitude},#{tenant_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
        ws[counter, 3] = tenant_record.is_geo_coded
        ws[counter, 4] = tenant_record.comp_view_type
        ws[counter, 5] = tenant_record.company
        ws[counter, 6] = tenant_record.industry_type
        ws[counter, 7] = tenant_record.address1
        ws[counter, 8] = tenant_record.suite
        ws[counter, 9] = tenant_record.city
        ws[counter, 10] = tenant_record.state
        ws[counter, 11] = tenant_record.country
        ws[counter, 12] = tenant_record.submarket
        ws[counter, 13] = tenant_record.class_type
        ws[counter, 14] = tenant_record.property_type
        ws[counter, 15] = tenant_record.property_name
        ws[counter, 16] = tenant_record.lease_commencement_date
        ws[counter, 17] = tenant_record.lease_term_months
        ws[counter, 18] = tenant_record.free_rent
        ws[counter, 19] = tenant_record.size
        ws[counter, 20] = tenant_record.deal_type
        ws[counter, 21] = (tenant_record.lease_structure.present?) ?  tenant_record.lease_structure : 'Full Service'
        ws[counter, 22] = tenant_record.base_rent
        ws[counter, 23] = tenant_record.tenant_improvement
        ws[counter, 24] = tenant_record.additional_tenant_cost
        ws[counter, 25] = tenant_record.additional_ll_allowance
        ws[counter, 26] = tenant_record.escalation
        ws[counter, 27] = tenant_record.is_stepped_rent
        ws[counter, 28] = tenant_record.fixed_escalation
        tenant_record.stepped_rents.each do |sr|
          ws[counter, stepped_rent_col] = sr.cost_per_month
          ws[counter, stepped_rent_col+1] = sr.months
          stepped_rent_col+=2
        end
        custom_field_col = stepped_rent_col
        if TenantRecord.max_stepped_rent_by_user(id).first!=nil
          custom_field_col = 29+TenantRecord.max_stepped_rent_by_user(id).first.countof*2
        end
        while stepped_rent_col<=custom_field_col
          ws[counter,stepped_rent_col]=''
          stepped_rent_col+=1
        end
        custom_data = TenantRecord.custom_field_values(tenant_record.id)
        custom_headers.each do
          custom_data.each do |vals|
            if ws[1, custom_field_col]==vals.header
              ws[counter, custom_field_col] = vals.value
              break
            else
              ws[counter, custom_field_col] = ''
            end
          end
          custom_field_col+=1
        end
        ws[counter, custom_field_col] = ''
        counter+=1
        ws.save()
      end
      if counter>2
        counter-=1
      end
      if ws.max_rows>counter
        ws.delete_rows(counter+1,ws.max_rows-counter)
      end
      ws.save()
  end
end