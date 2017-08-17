class DatabaseSaleWorker
  include Sidekiq::Worker
  require "google_drive"
  require 'digest/sha1'
  require 'time'
  include GoogleGeocoder
  sidekiq_options queue: "high"

  def perform(file_temp,id)
    sale_records = SaleRecord.where('user_id = ?', id).order(:id)
    custom_headers = SaleRecord.custom_field_headers(id)
    session = GoogleDrive::Session.from_config("#{Rails.root}/config/google-sheets.json")
    ws = session.spreadsheet_by_key(file_temp).worksheets[0]
    counter=2
    custom_headers_col_head = 19
    custom_headers.each do |keys|
      ws[1,custom_headers_col_head]= keys.header
      custom_headers_col_head+=1
    end
    sale_records.each do |sale_record|
      ws[counter, 1] = sale_record.id
      ws[counter, 2] = (sale_record.main_image_file_name.present?) ? sale_record.main_image_file_name : '=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location='+"#{sale_record.latitude},#{sale_record.longitude}"+'&heading=151.78&pitch=-0.76",2)'
      ws[counter, 3] = sale_record.is_geo_coded
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
      ws[counter, 17] = (sale_record.is_sales_record) ? "Building Record":"Land Record"
      ws[counter, 18] = sale_record.cap_rate
      custom_field_col = 19

      custom_data = SaleRecord.custom_field_values(sale_record.id)
      custom_headers.each do
        custom_data.each do |vals|
          if ws[1, custom_field_col]==vals.header
            ws[counter, custom_field_col] = vals.value
            break
          else
            ws[counter, custom_field_col] = ''
            next
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