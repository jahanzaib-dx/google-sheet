include CushmanCalculationEngine
include GoogleGeocoder

module Importer

  def self.validate original_record, import_id, record_id = nil, current_user_info

    import = TenantRecordImport.find import_id
    record = self.template_converted_data(import, original_record)
    params = record.merge( :office_id => import.office_id )

    tenant_record = TenantRecord.new do |t|
      params.each_pair { |k,v|
        t.send "#{k.to_s}=", v if !self.is_stepped_rent_params(k.to_s)
      }
    end

    # just save custom
    tenant_record.custom = original_record[:custom] if original_record[:custom]
    # just set the team
    tenant_record.team = import.team

    # checking stepped rent and if it has errors
    has_stepped_errors = self.validate_stepped_rents(record)

    tenant_record.validate_all = true

    if !tenant_record.valid? || has_stepped_errors

      # create a tmp record if one doesnt exist
      unless record_id
        record = self.process_custom_fields(original_record, record) if original_record[:custom]
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

      if tenant_record.latitude.blank? or tenant_record.longitude.blank?
        record = self.process_custom_fields(original_record, record) if original_record[:custom] && !record_id
        self.geocode_record import_id, record_id, record, tenant_record, tmp_record, has_stepped_errors, current_user_info
      else
        self.finish_import import_id, record_id, record, tenant_record, current_user_info
      end

    end
    # update import record flags
    import.update_flags
  end

  def self.process_custom_fields original_record, record
    custom_fields = {}
    original_record[:custom].each{|k, v| custom_fields.merge!({k.to_sym => v['value'].to_s})}
    record.merge!(:custom => custom_fields)
  end

  # helper stuff
  #
  def self.finish_import import_id, record_id, record, tenant_record, current_user_info
    tenant_record.stepped_rents = self.save_stepped_rent(record, tenant_record.id)
    #import to tenant records and remove the temp_record

    if current_user_info == "cushman" && tenant_record.stepped_rents.present?
      cushman_results = retrieve_cushman_metrics(tenant_record)
      tenant_record.cushman_net_effective_per_sf = cushman_results[:net_effective_rent]
    end
    tenant_record.is_stepped_rent = true if tenant_record.stepped_rents.present?
    tenant_record.save!

    Rails.logger.debug "Import Success: #{tenant_record.id}"

    TenantRecordImport.increment_counter(:num_imported_records, import_id)
    ImportLog.create(tenant_record_import_id: import_id,
                     office_id: tenant_record.office.id,
                     tenant_record_id: tenant_record.id )
    if record_id
      ImportRecord.destroy record_id
      Rails.logger.debug "Import Record Destroyed: #{record_id}"
    end

  end

  def self.geocode_record import_id, record_id, record, tenant_record, tmp_record, has_stepped_errors, current_user_info
    begin
      ################# geocode with Google #########################
      google_results = geocode_address(tenant_record)
      geocode_results = parse_geocode_response(google_results["results"])
      geocode_results = get_unique_hash_using_standard_attributes(geocode_results, tenant_record)
    rescue Exception => e
      Rails.logger.error [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
      geocode_results = nil
    end

    if (!geocode_results.nil? && geocode_results.length == 1 && validate_address_types(geocode_results.first))
      geo = geocode_results.first

      # use verified address
      tenant_record.address1 = (geo[:address1].present? ? geo[:address1] : tenant_record.address1)
      tenant_record.zipcode = geo[:zipcode]

      # update lat & lon
      tenant_record.latitude = geo[:latitude]
      tenant_record.longitude = geo[:longitude]

      self.finish_import import_id, record_id, record, tenant_record, current_user_info

    else # add geocode errors
      # update errors on tmp_record or create a tmp_record if one doesnt exist
      if !tmp_record
        tmp_record = ImportRecord.find_by_id record_id
        if !tmp_record
          # create a tmp_record
          tmp_record = ImportRecord.create(:tenant_record_import_id => import_id,
                                           :data => record)
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
  end

  def self.hash_format import_id, h
    # h is the spreadsheet row
    mappings = ImportTemplate.unscoped.find(TenantRecordImport.find(import_id).import_template_id).import_mappings
    custom = {}
    hashed_record = Hash[h.map do |k, v|
      sheet_col = k.gsub(/\ /, "_").gsub("\n","_").downcase.to_sym
      mapping = mappings.find {|m| m.spreadsheet_column.present? && (m.spreadsheet_column.to_sym == sheet_col) }
      if !mapping.nil?
        key, val = (self.edge_case_format Hash[mapping.record_column, v]).to_a.first
        #calc_types << key if key.to_s.match(/^leasestructure_expenses/)
        #keep formatted original key with modified edge case value
        [mapping.record_column.to_sym, val]
      else
        custom[sheet_col] = Hash["key", k, "value", v]
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
    required_total, actual_total = *self.validate_stepped_rents_matches_lease_term_months(record)
    required_total != actual_total
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
