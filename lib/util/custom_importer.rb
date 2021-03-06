include CushmanCalculationEngine
include GoogleGeocoder

module CustomImporter

  def self.validate original_record, import_id, record_id = nil, current_user_info, not_for_sheet

    import = TenantRecordImport.find import_id
    record = self.template_converted_data(import, original_record)
    params = record.merge( "user_id" => import.user_id )
    p not_for_sheet
    klass = Object.const_get not_for_sheet['class']

    if not_for_sheet['class'] == 'CustomRecord'
      tenant_record = CustomRecord.where({name: not_for_sheet['name'], user_id: import.user_id}).last
      Rails.logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      Rails.logger.debug tenant_record.inspect
      if tenant_record.nil?
        tenant_record = CustomRecord.new({name: not_for_sheet['name'], is_geo_coded: not_for_sheet['is_geo_coded'], is_existing_data_set: not_for_sheet['is_existing_data_set']})
        tenant_record.custom_record_properties = []
      end
    else
      tenant_record = klass.new do |t|
        params.each_pair { |k,v|
          t.send "#{k.to_s}=", v if !self.is_stepped_rent_params(k.to_s)
        }
      end
    end

    if not_for_sheet['class'] == 'TenantRecord'
      p original_record.inspect

      original_record_old=original_record


      if not_for_sheet['has_lease_structure']== true

        if (not_for_sheet['lease_structure']).present?
          #ls= LeaseStructure.new("name"=> original_record[:custom][:lease_structure]["value"])
          ls= LeaseStructure.new("name"=> not_for_sheet['lease_structure'].to_s)
          tenant_record.set_lease_structure ls
        else
          ls= LeaseStructure.new("name"=>'Full Service')
          tenant_record.set_lease_structure ls
        end
      end
      if not_for_sheet.key?('base_rent_type') && not_for_sheet['base_rent_type'] == 'monthly'
        tenant_record.base_rent = tenant_record.base_rent.to_f * 12
      end

      if not_for_sheet['rent_escalation_type_percent'] && not_for_sheet['rent_escalation_type_fixed'] && not_for_sheet['rent_escalation_type_stepped']
        if tenant_record.base_rent.to_f > 0.0
          if tenant_record.escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_percent'
          elsif tenant_record.fixed_escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_fixed_increase'
          end
        else
          tenant_record = self.process_tenantrecord_stepped_rent tenant_record, not_for_sheet,original_record
        end
      elsif not_for_sheet['rent_escalation_type_percent'] && not_for_sheet['rent_escalation_type_fixed']
        if tenant_record.base_rent.to_f > 0.0
          if tenant_record.escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_percent'
          elsif tenant_record.fixed_escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_fixed_increase'
          end
        end
      elsif not_for_sheet['rent_escalation_type_percent'] && not_for_sheet['rent_escalation_type_stepped']
        if tenant_record.base_rent.to_f > 0.0
          if tenant_record.escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_percent'
          else
            tenant_record = self.process_tenantrecord_stepped_rent tenant_record, not_for_sheet,original_record
          end
        end
      elsif not_for_sheet['rent_escalation_type_fixed'] && not_for_sheet['rent_escalation_type_stepped']
        if tenant_record.base_rent.to_f > 0.0
          if tenant_record.fixed_escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_fixed_increase'
          else
            tenant_record = self.process_tenantrecord_stepped_rent tenant_record, not_for_sheet,original_record
          end
        end
      elsif not_for_sheet['rent_escalation_type_percent']
        if tenant_record.base_rent.to_f > 0.0
          if tenant_record.escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_percent'
          end
        end
      elsif not_for_sheet['rent_escalation_type_fixed']
        if tenant_record.base_rent.to_f > 0.0
          if tenant_record.fixed_escalation.to_f > 0.0
            tenant_record.rent_escalation_type = 'base_rent_fixed_increase'
          end
        end
      elsif not_for_sheet['rent_escalation_type_stepped']
        tenant_record = self.process_tenantrecord_stepped_rent tenant_record, not_for_sheet, original_record
      end

      #p tenant_record
      #not_for_sheet = not_for_sheet.except(:rent_escalation_type_percent)
      #not_for_sheet = not_for_sheet.except(:rent_escalation_type_fixed)
      #not_for_sheet = not_for_sheet.except(:rent_escalation_type_stepped)
      #not_for_sheet = not_for_sheet.except(:additional_cost)
      #not_for_sheet = not_for_sheet.except(:stepped_rents)
      #not_for_sheet = not_for_sheet.except(:lease_stepped_rents)

      if not_for_sheet['free_rent_type_consecutive'] && not_for_sheet['free_rent_type_non_consecutive']
        if(tenant_record.free_rent.to_s.include? "-" || tenant_record.free_rent.to_s.include?(","))
          tenant_record.free_rent_type = 'non consecutive'
        else
          tenant_record.free_rent_type = 'consecutive'
        end
      elsif not_for_sheet['free_rent_type_consecutive']
        if(tenant_record.free_rent.to_s.include? "-" || tenant_record.free_rent.to_s.include?(","))
          puts "error"
        else
          tenant_record.free_rent_type = 'consecutive'
        end
      elsif not_for_sheet['free_rent_type_non_consecutive']
        if(tenant_record.free_rent.to_s.include? "-" || tenant_record.free_rent.to_s.include?(","))
          tenant_record.free_rent_type = 'consecutive'
        else
          puts "error"
        end
      end
      not_for_sheet = not_for_sheet.except('free_rent_type_consecutive')
      not_for_sheet = not_for_sheet.except('free_rent_type_non_consecutive')
      if not_for_sheet.key?('is_tenant_improvement') && !(not_for_sheet['is_tenant_improvement'])
        tenant_record.tenant_improvement = 0.0
      end
      if not_for_sheet.key?('has_additional_tenant_cost') && !(not_for_sheet['has_additional_tenant_cost'])
        not_for_sheet[:additional_tenant_cost] = 0.0
      end
      if not_for_sheet.key?('has_additional_ll_allowance') && !(not_for_sheet['has_additional_ll_allowance'])
        not_for_sheet[:additional_ll_allowance] = 0.0
      end
      hash = original_record[:custom]
      if !hash.nil?
        a= hash.values
        b = a.map { |h| [h["key"] , h["value"]] }.to_h
        tenant_record.custom_data = b
      end
    elsif not_for_sheet['class'] == 'SaleRecord'
      hash = original_record[:custom]
      if !hash.nil?
        a= hash.values
        b = a.map { |h| [h["key"] , h["value"]] }.to_h
        tenant_record.custom = b
      end
    elsif not_for_sheet['class'] == 'CustomRecord'

      Rails.logger.debug "@@@@@@@@@@@@@@@@@@@@"
      Rails.logger.debug not_for_sheet.inspect



      hash = original_record[:custom]
      unless hash.nil?
        a= hash.values
        a.each do |h|
          property = CustomRecordProperty.new({key: h["key"], value: h["value"]})
          tenant_record.custom_record_properties << property
        end
      end
    end



    not_for_sheet = not_for_sheet.except('class')
    p not_for_sheet
    # just save custom
    # hash = original_record[:custom]
    # if !hash.nil?
    #   a= hash.values
    #   b = a.map { |h| [h["key"] , h["value"]] }.to_h
    #   tenant_record.custom = b
    # end

    tenant_record.is_geo_coded= not_for_sheet['is_geo_coded']
    # just set the team
    #tenant_record.team = import.team
    tenant_record.user = import.user

    # checking stepped rent and if it has errors
    has_stepped_errors =self.validate_stepped_rents(record)

    #tenant_record.validate_all = true

    # to show suggestions in error view
    if !tenant_record.valid? || has_stepped_errors

      # create a tmp record if one doesnt exist
      unless record_id
        record = self.process_custom_fields(original_record, record) if original_record[:custom]
        unless record[:custom]
          record[:custom] = {}
        end
        record[:custom].merge!(:class => klass.to_s)

        tmp_record = ImportRecord.create(:tenant_record_import_id => import_id,
                                         :data => record)
      else
        tmp_record = ImportRecord.find record_id
      end

      tmp_record.geocode_valid = false if tenant_record.errors.detect do |e|
        e[0] == :address || e[0] == :city || e[0] == :state || e[0] == :zipcode
      end
      tmp_record.record_valid = false
      tmp_record.record_errors = tenant_record.errors.to_hash

     required, stepped_total = *self.validate_stepped_rents_matches_lease_term_months(record)
      if has_stepped_errors
         tmp_record.record_errors = tmp_record.record_errors.
           merge(Hash[:stepped_errors, "Stepped rent months need to add up to the lease term.<br><br>The lease term is #{required} months and the stepped rent adds up to #{stepped_total} months."])
      end
      tmp_record.save
    end

    # record valid, now geocode/save
    if tenant_record.valid? && !has_stepped_errors

      if record_id
        tmp_record = ImportRecord.find record_id
        tmp_record.record_valid = tenant_record.valid?
        tmp_record.record_errors.clear
        tmp_record.save
      end


      do_geocoding = false
      if (tenant_record.latitude.blank? or tenant_record.longitude.blank?)
        if klass.to_s.eql?("CustomRecord")
          do_geocoding = not_for_sheet['is_geo_coded']
        else
          do_geocoding = true
        end
      else
        do_geocoding = false
      end

      #Rails.logger.debug "$%$%$%$%$%$%$%$%$%$%"
      #Rails.logger.debug ":is_geo_coded : #{not_for_sheet[:is_geo_coded].inspect}"
      #Rails.logger.debug ":do_geocoding : #{do_geocoding.inspect}"

      if do_geocoding
        record = self.process_custom_fields(original_record, record) if original_record[:custom] && !record_id
        unless record[:custom]
          record[:custom] = {}
        end
        record[:custom].merge!(:class => klass.to_s)
        self.geocode_record import_id, record_id, record, tenant_record, tmp_record, has_stepped_errors, current_user_info, not_for_sheet
      else
        self.finish_import import_id, record_id, record, tenant_record, current_user_info, not_for_sheet
      end
=begin
      if tenant_record.latitude.blank? or tenant_record.longitude.blank?
        record = self.process_custom_fields(original_record, record) if original_record[:custom] && !record_id

        unless record[:custom]
          record[:custom] = {}
        end
        record[:custom].merge!(:class => klass.to_s)

        self.geocode_record import_id, record_id, record, tenant_record, tmp_record, has_stepped_errors, current_user_info, not_for_sheet
      else
        self.finish_import import_id, record_id, record, tenant_record, current_user_info, not_for_sheet
      end
=end

    end
    # update import record flags
    import.update_flags
  end

  def self.process_custom_fields original_record, record
    custom_fields = {}
    original_record[:custom].each{|k, v| custom_fields.merge!({k.to_sym => v['value'].to_s})}
    record.merge!(:custom => custom_fields)
  end

  def self.process_tenantrecord_stepped_rent tenant_record, not_for_sheet,original_record
    tenant_record.rent_escalation_type = 'stepped_rent'
    tenant_record.is_stepped_rent = true
    not_for_sheet['lease_stepped_rents'].each { |step|
          tenant_record.stepped_rents.new(:cost_per_month => step['cost_per_month'], :months => step['months'])
    }


tenant_record
  end

  # helper stuff
  #
  def self.finish_import import_id, record_id, record, tenant_record, current_user_info, not_for_sheet

    #import to tenant records and remove the temp_record

=begin
    if current_user_info == "cushman" && defined?(tenant_record.stepped_rents) != nil && tenant_record.stepped_rents.present?
      cushman_results = retrieve_cushman_metrics(tenant_record)
      tenant_record.cushman_net_effective_per_sf = cushman_results[:net_effective_rent]
    end
=end
    tenant_record.is_stepped_rent = true if defined?(tenant_record.stepped_rents) != nil && tenant_record.stepped_rents.present?


    #tenant_record.assign_attributes not_for_sheet.except('custom_record_properties')
    if tenant_record.class.to_s == 'CustomRecord'
      if not_for_sheet['custom_record_properties']
        not_for_sheet['custom_record_properties'].merge(record[:custom].except(:class))
      end
    end

    if tenant_record.save
      if (tenant_record.class.to_s == 'CustomRecord' && (not_for_sheet['custom_record_properties'].count) > 0 rescue false)
        not_for_sheet['custom_record_properties'].each do |index, hash|
          tenant_record.custom_record_properties.create(hash)
        end
      end
    end

    Rails.logger.debug "Import Success: #{tenant_record.id}"

    TenantRecordImport.increment_counter(:num_imported_records, import_id)
    ImportLog.create(tenant_record_import_id: import_id,
                     user_id: tenant_record.user.id,
                     tenant_record_id: tenant_record.id )
    if record_id
      ImportRecord.destroy record_id
      Rails.logger.debug "Import Record Destroyed: #{record_id}"
    end

  end

  def self.geocode_record import_id, record_id, record, tenant_record, tmp_record, has_stepped_errors, current_user_info, not_for_sheet
   if not_for_sheet['is_geo_coded']

    begin
      ################# geocode with Google #########################
      google_results = GoogleGeocoder.geocode_address(tenant_record)
      geocode_results = GoogleGeocoder.parse_geocode_response(google_results["results"])
      geocode_results = GoogleGeocoder.get_unique_hash_using_standard_attributes(geocode_results, tenant_record)
    rescue Exception => e
      Rails.logger.error [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
      geocode_results = nil
    end

    if (!geocode_results.nil? && geocode_results.length == 1 && GoogleGeocoder.validate_address_types(geocode_results.first))
      geo = geocode_results.first

      # use verified address
      tenant_record.address1 = (geo[:address1].present? ? geo[:address1] : tenant_record.address1)
      tenant_record.zipcode = geo[:zipcode]

      # update lat & lon
      tenant_record.latitude = geo[:latitude]
      tenant_record.longitude = geo[:longitude]


      self.finish_import import_id, record_id, record, tenant_record, current_user_info, not_for_sheet

    else # add geocode errors
      # update errors on tmp_record or create a tmp_record if one doesnt exist
      if !tmp_record
        tmp_record = ImportRecord.find_by_id record_id
        if !tmp_record
          # create a tmp_record
          tmp_record = ImportRecord.create(:tenant_record_import_id => import_id,
                                           :data => record)

          tmp_record.record_errors = {}
        end
      end
      tmp_record.geocode_valid = false
      tmp_record.record_valid = tenant_record.valid?

      if geocode_results.blank? || geocode_results.length == 1
        tmp_record.record_errors = tmp_record.record_errors.merge Hash[:geocode_info, ["There was an error with the address. Please check the address fields and submit again."]]
      else
        #add notifications from google geocode
        geo_errors = add_notifications(tmp_record, geocode_results) rescue Hash[:geocode_info, ["There was an error with the address. Please check the address fields and submit again."]]
        tmp_record.record_errors = tmp_record.record_errors.merge(geo_errors)
      end

      tmp_record.record_errors = tmp_record.record_errors.except("stepped_errors") if !has_stepped_errors
      tmp_record.save
    end
   else
     self.finish_import import_id, record_id, record, tenant_record, current_user_info, not_for_sheet
   end

  end

  def self.hash_format import_id, h, already_mapped_columns
    # h is the spreadsheet row
    mappings = ImportTemplate.unscoped.find(TenantRecordImport.find(import_id).import_template_id).import_mappings
    custom = {}
    mapped_hash=already_mapped_columns.values.map { |h| [h[:id] , h[:spreadsheet_column]] }.to_h
    hashed_record = Hash[h.map do |k, v|

      sheet_col = k.gsub(/\ /, "_").gsub("\n","_").downcase.to_sym
      mapping = mappings.find {|m| m.spreadsheet_column.present? && (m.spreadsheet_column.to_sym == sheet_col) }
      if !mapping.nil?
        key, val = (self.edge_case_format Hash[mapping.record_column, v]).to_a.first
        #calc_types << key if key.to_s.match(/^leasestructure_expenses/)
        #keep formatted original key with modified edge case value
        [mapping.record_column.to_sym, val]
      else
        mapped_fields=mapped_hash.has_value? k
        if !mapped_fields
          custom[sheet_col] = Hash["key", k, "value", v]
        end

      end
    end]
    # adding custom fields (aka, non-required tenantrex fields
    hashed_record[:custom] = custom
    # add entries for the calc types
    mappings.calc_types.each { |m| hashed_record[m.record_column.to_sym] = m.default_value }
    hashed_record
  end

  private

  # Gets template and defines default values if they didn't exist in spreadsheet
  def self.template_converted_data import, record
    converted_data = Hash.new
    ImportTemplate.unscoped.find(import.import_template_id).import_mappings.each do |mapping|
      result = if record[mapping.record_column.to_sym].present?
                 Hash[mapping.record_column.to_sym, record[mapping.record_column.to_sym]]
               else
                 Hash[mapping.record_column.to_sym, mapping.default_value]
               end
      converted_data.merge!( edge_case_format result  )
    end
    converted_data
   end

  def self.edge_case_format h
    key, val = h.to_a.first

    # format dates
    if (key == :lease_commencement_date || key == :lease_expiration_date) && val.is_a?(String) && !val.nil? && !val.index('/').nil?
      val = DateTime.strptime(val, '%m/%d/%Y')
    end

    # snake case options
    if key == :class_type ||
       key == :comp_type  ||
       key == :view_type  ||
       key == :lease_structure_type  ||
       key == :location_type  ||
       key == :property_type

      val = val.gsub(/\ /, "_").downcase if !val.nil?
      if key == :lease_structure_type && val == "nnn"
        val = val.upcase
      end
    end

    # format integers
    if key == :size ||
       key == :lease_term_months ||
       match_rent_months(key.to_s)
      return key => val.try(:to_i)
    end

    # format zipcode
=begin
    if key == :zipcode
      return key => val.try(:to_s)
    end
=end

    # format floats
    if key == :escalation
      return key => val.try(:to_f)
    end

    # format phone
    if key == :contact_phone && !val.nil?
      if val.class == Float
        return key => val.to_i
      else
        return key => val.to_s.gsub( /[^0-9]/, '' )
      end

    end
    {key => val}
  end

  def self.validate_stepped_rents(record)
    return false if record.keys.any? {|k, v| k.to_s.include? "base_rent"}
    required_total, actual_total = *self.validate_stepped_rents_months_exist(record)
    required_total <= actual_total
  end

  def self.validate_stepped_rents_matches_lease_term_months(record)
    required_months = record[:lease_term_months].to_i
    total_months = 0
    record.keys.each do |f|
      if self.match_rent_months(f.to_s)
        total_months += record[f]
      end
      if self.match_rent(f.to_s)
        record[f] = 0.0 if record[f].blank?
      end
    end
    [required_months, total_months]
  end
  def self.validate_stepped_rents_months_exist(record)
    required_rents = 1
    total_rents = 0
    record.keys.each do |f|
      if self.match_rent_months(f.to_s)
        total_months +=1
      end
      if self.match_rent(f.to_s)
        total_rents+=1 if !record[f].blank?
      end
    end
    [required_rents, total_rents]
  end

  def self.is_stepped_rent_params(str)
    self.match_rent(str) or self.match_rent_months(str)
  end

  def self.match_rent(str)
   str.match(/rent_\d*_\(\$\/sf\)$/)
  end

  def self.match_rent_months(str)
    str.match(/rent_\d*_#_of_months$/)
  end

  #def self.save_stepped_rent( record, tenant_record_id)
  #  stepped_rents = []
  #  record.keys.each do |f|
  #    if match_rent_months(f.to_s)
  #      order = /\d+/.match(f.to_s)
  #      cost = record["rent_#{order}_\(\$\/sf\)".to_sym]
  #      months = record["rent_#{order}_#_of_months".to_sym]
  #      stepped_rents << SteppedRent.create(tenant_record_id: tenant_record_id,
  #                        order: order,
  #                        months: months,
  #                        cost_per_month: cost)
  #   end
  #  end
  #  stepped_rents
  #end

  def self.save_stepped_rent( record, tenant_record_id)
    stepped_rents = []
    record.keys.each do |f|
      if match_rent_months(f.to_s)
        order = /\d+/.match(f.to_s)
        cost = record["rent_#{order}_\(\$\/sf\)".to_sym]
        months = record["rent_#{order}_#_of_months".to_sym]
        stepped_rents << SteppedRent.create(tenant_record_id: tenant_record_id,
                          order: order,
                          months: months,
                          cost_per_month: cost)
     end
    end
    stepped_rents
  end

end
