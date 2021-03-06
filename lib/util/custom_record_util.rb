module CustomRecordUtil

  include GoogleGeocoder
  include ExtendedHash

  def self.process_bulk_upload(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings, not_for_sheet)
    import = TenantRecordImport.find(import_id)
    begin
      File.open(tmp_file_path, "rb") do |file|
        case File.extname(original_filename)
          when ".xls"  then @sheet = Roo::Excel.new(file.path)
          when ".xlsx" then @sheet = Roo::Excelx.new(file.path)
          when ".csv"  then @sheet = Roo::CSV.new(file.path)
          else raise Exception.new("Unknown file type: #{File.extname(original_filename)}")
        end
      end

      column_names = []
      @sheet.default_sheet = @sheet.sheets.first
      raise Exception.new("Empty excel document") if @sheet.first_column.nil?

      @sheet.first_column.upto @sheet.last_column do |col|
        column =  @sheet.cell( @sheet.first_row, col )
        raise Exception.new("##{col} column has no header name defined") if column.nil?
        column_names << column.to_s.strip
      end
      #p column_names
      errors = ""

      #template          = ImportTemplate.unscoped.find(template_id)
      #template_columns  = Hash[template.import_mappings.map { |x| [x.record_column, x.spreadsheet_column] }]
      #formatted_columns = ImportTemplateUtil.symbolize_keys(column_names).keys.map { |x| x.to_s.strip }

      if(not_for_sheet[:is_geo_coded])
        missing_columns   = ImportTemplateUtil.symbolize_keys(template_columns.values).keys.map { |x| x.to_s.strip } - formatted_columns
        required_columns = ["address1","city", "state", "country"]
        # db columns - spreadsheet columns
        if !missing_columns.empty?
          missing_columns.each do |column|
            if required_columns.include?(column.to_s)
              errors += column.to_s.split('_').map(&:capitalize).join(' ') + "\n"
            end
          end
        end

        unless errors.empty?
          raise Exception.new errors + "\nMake sure your file has all the above column headings. No trailing whitespace allowed."
        end
      end

      row_offset = 1
      total = @sheet.last_row - row_offset
      if (total <= 0)
        import.update_attributes(:total_record_count => total)
        raise Exception.new("No records found.")
      end

      import.update_attributes(:status => "Validating records...", :total_record_count => total)

      params = { "name" => not_for_sheet['name'],
                 "is_existing_data_set" => not_for_sheet['is_existing_data_set'],
                 "is_geo_coded" => not_for_sheet['is_geo_coded'],
                 "existing-data-set-dd" => not_for_sheet['existing_data_set_dd']
      }

      address_header_hash = {}
      log "not_for_sheet['is_geo_coded']: #{not_for_sheet['is_geo_coded'].inspect}"
      if not_for_sheet['is_geo_coded'] == 'on'
        address_header_hash = not_for_sheet["address_mapping"]
        log "address_header_hash: #{address_header_hash.inspect} "
        if not_for_sheet['is_existing_data_set'] == 'no'
          params["address1"] = address_header_hash["address1"]
          params["city"] = address_header_hash["city"]
          params["state"] = address_header_hash["state"]
          params["country"] = address_header_hash["country"]
        end
      end

      custom_record = process_custom_record(params,import.user)
      num_imported_records = 0
      @sheet.parse(:header_search => column_names[0..1], :clean => true).each_with_index do |sheet_row, i|
        if i >= 0
          row = sheet_row
          TenantRecordImport.increment_counter(:total_traversed_count, import_id)
          custom_record_properties = []

          if(custom_record.is_geo_coded)
            address_header_hash = {
                :address1 => custom_record[:address1],
                :city => custom_record[:city],
                :state => custom_record[:state],
                :country => custom_record[:country],
            }
            log "address has affter assigning map values: #{address_header_hash.inspect}"
            address_header_hash.keys.each do |key|
              log "#{key} => #{row[ address_header_hash[key] ]} "
              custom_record_properties << {:key => key, :value => row[ address_header_hash[key] ]}
                row.except!( address_header_hash[key] )
            end
          end

          row.keys.each do |col|
            custom_record_properties << { :key => col, :value => row[ col ]}
          end
          begin
            process_custom_record_properties(custom_record, custom_record_properties)
            num_imported_records += 1
            import.update_attributes(:status => "Importing records...", :num_imported_records => num_imported_records)
          rescue => exception
            Rails.logger.info("Exception while GeoCoding ... ")
            Rails.logger.info exception.message
          end

        end
      end

      #TenantRecordImport.increment_counter(:num_imported_records, import_id)

      if(total > num_imported_records)
        import.update_attributes(:status => "Some records have issues. Please check the address and upload them again.", :complete => true, :import_valid => false, :completed_at => DateTime.current())
      else
        import.update_attributes(:status => "Import has completed", :num_imported_records => num_imported_records, :complete => true, :import_valid => true, :completed_at => DateTime.current())
      end


      ImportLog.create(tenant_record_import_id: import_id,
          user_id: custom_record.user_id,
          tenant_record_id: custom_record.id)



    rescue IOError => e
      import.update_attribute('status', ["File upload failed at", DateTime.current().to_s].join(' '))
      puts [e.message, e.backtrace.join("\n")].join("\n")
      Rails.logger.debug [e.message, e.backtrace.join("\n")].join("\n")
    rescue NoMethodError => e
      import.update_attributes(:status => ["Import error at", DateTime.current().to_s].join(' '))
      puts [e.message, e.backtrace.join("\n")].join("\n")
      Rails.logger.error [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
    rescue Exception => e
      import.update_attributes(:status => e.message)
      puts [e.message, e.backtrace.join("\n")].join("\n")
      Rails.logger.error [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
    end
  end

  def self.process_single_record custom_record_params, current_user

    # since when adding a new custom record set, address information in not part of param's custom_record_properties_attributes
    # array and when adding row to already saved set, it is part of the array, I'll have to do the following
    address = ["address1","city","state","country","latitude", "longitude","zipcode"]
    custom_record_properties = []
    custom_record_params[:custom_record_properties_attributes].each do |property|
      unless property[1]["value"].blank?
        custom_record_properties << {:key => property[1]["key"], :value => property[1]["value"]}
      end
    end

    log "custom_record_params before geocoding #{custom_record_properties.inspect}"

    if custom_record_params["is_geo_coded"]
      if custom_record_params["is_existing_data_set"] == 'no'
        custom_record_properties << {:key=> "address1", :value=> custom_record_params[:address1] }
        custom_record_properties << {:key=> "city", :value=> custom_record_params[:city] }
        custom_record_properties << {:key=> "state", :value=> custom_record_params[:state] }
        custom_record_properties << {:key=> "country", :value=> custom_record_params[:country] }
      end
      custom_record_properties << {:key=> "latitude", :value=> "" }
      custom_record_properties << {:key=> "longitude", :value=> "" }
      custom_record_properties << {:key=> "zipcode", :value=> "" }

      log "custom_record_properties_attributes after geocoding"
      log custom_record_properties.inspect
    end

    custom_record_params.except!(:address1,:city,:state,:country)
    #begin
      custom_record = process_custom_record_properties(process_custom_record(custom_record_params, current_user), custom_record_properties)
    #rescue => exception
      #Rails.logger.info("Exception while GeoCoding ... ")
      #Rails.logger.info exception.message
    #end
    return custom_record

  end
















  def self.process_custom_record(custom_record_params, current_user)

    model_parameters = { :name => custom_record_params["name"],
                         :is_existing_data_set => custom_record_params["is_existing_data_set"] == 'yes' ? true : false,
                         :is_geo_coded => custom_record_params["is_geo_coded"].nil? ? false : true,
                         :user_id => current_user.id
    }
    #Sidekiq.logger.debug "model_parameters #{model_parameters.inspect}"
    log "model_parameters[:is_existing_data_set] #{model_parameters[:is_existing_data_set].inspect}"
    if model_parameters[:is_existing_data_set]
      log "custom_record_params #{custom_record_params.inspect} "
      custom_record = CustomRecord.find(custom_record_params["existing-data-set-dd"])
    else
      if model_parameters[:is_geo_coded]
        model_parameters[:address1] = custom_record_params["address1"]
        model_parameters[:city] = custom_record_params["city"]
        model_parameters[:state] = custom_record_params["state"]
        model_parameters[:country] = custom_record_params["country"]
      end
      custom_record = CustomRecord.create(model_parameters)
    end

    log custom_record.inspect
    return custom_record
  end





  def self.process_custom_record_properties custom_record, custom_record_properties

    log "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    log "custom_record"
    log custom_record.inspect

    log "custom_record_properties_attributes"
    log custom_record_properties.inspect


    address = ["address1","city","state","country","latitude", "longitude","zipcode"]
    address_hash = blank_address_hash

    if custom_record.is_geo_coded

      custom_record_properties.each do |property|
          log "property"
          log property.inspect
          col = property[:key]
          if address.include?(col)
            val = property[:value]
            address_hash[col.to_sym] = val
          end
      end

      log "adress has before validation: #{address_hash.inspect}"
      result = GoogleGeocoder.validate_address_google(address_hash, true)
      log "geocoding result #{result.inspect}"

        if result.has_key? :coords
          address_hash[:latitude] = result[:coords][:latitude]
          address_hash[:longitude] = result[:coords][:longitude]
        end

        if result.has_key? :updates
          address_hash[:latitude] = result[:updates][:latitude]
          address_hash[:longitude] = result[:updates][:longitude]
          address_hash[:zipcode] = result[:updates][:zipcode]
        end

        log "address_hash #{address_hash.inspect}"
        custom_record_properties.each_with_index do |property, index|
          log "property: #{property.inspect}"
          col = property[:key]
          if address.include? col
            custom_record_properties[index]["value"] =  address_hash[col.to_sym]
          end
        end
    end

    row_id = custom_record.get_next_row_number
    custom_record_properties.each do |property|
      property['row_id'] = row_id
      property['custom_record_id'] = custom_record.id
      CustomRecordProperty.create( property )
    end


    CustomRecordProperty.where(:key => 'latitude').update_all(:visible => false)
    CustomRecordProperty.where(:key => 'longitude').update_all(:visible => false)
    CustomRecordProperty.where(:key => 'zipcode').update_all(:visible => false)

    custom_record = CustomRecord.find(custom_record.id)

    #log custom_record.inspect
    #custom_record.custom_record_properties.each { |crp| log crp.inspect }
    #abort("Message goes here")

    return custom_record
  end



  def self.log str
    Rails.logger.debug "\033[36m\033[1m #{str} \033[22m\033[0m"
    Sidekiq.logger.debug str
  end

  def self.start_coloured_log
    Rails.logger.debug "\033[36m\033[1m "
  end



  def self.blank_address_hash
    address_hash = {
        :address1 => "",
        :city => "",
        :state => "",
        :country=> "",
        :zipcode => "",
        :latitude => "",
        :longitude => ""
    }
    address_hash.extend(ExtendedHash)
    return address_hash
  end

end