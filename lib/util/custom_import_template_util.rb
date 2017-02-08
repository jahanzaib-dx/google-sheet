module CustomImportTemplateUtil

  def self.required?(obj, attr)
    target = (obj.class == Class) ? obj : obj.class
    target.validators_on(attr).map(&:class).include?(
      ActiveModel::Validations::PresenceValidator)
  end

  def self.update_import_mappings(template, mappings = [])
    mappings.each do |mapping|

      mapping = mapping.last
      mapping[:spreadsheet_column] = spreadsheet_columnize(mapping[:record_column]) if required?(TenantRecord, mapping[:record_column]) && mapping[:spreadsheet_column].empty?

      to_sym = symbolize_keys_and_values(mapping)

      ImportMapping.create import_template: template, spreadsheet_column: to_sym[:spreadsheet_column], record_column: to_sym[:record_column], default_value: mapping[:default_value]

    end
  end

  def self.spreadsheet_columnize(v)
    v.humanize.titleize.gsub(/\ /, '_').downcase
  end


  def self.create_template_spreadsheet(template)
    delete_template_spreadsheet(template)

    name = Rails.root.join("public", "spreadsheet_templates", "#{template.name.gsub(/\ /, '_')}.xls").to_s

    dir = File.dirname(name)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    book = WriteExcel.new name
    sheet = book.add_worksheet
    header = template.import_mappings(true).map do |mapping|
      next if mapping.spreadsheet_column.blank?
      mapping.spreadsheet_column.humanize.titleize
    end

    sheet.write_row(0, 0, header.compact)
    book.close

  end

  def self.delete_template_spreadsheet(file_name)
    name = Rails.root.join("public", "system", "marketrex_uploads", "#{file_name}").to_s
    File.delete(name) if File.exists?(name)
  end

  def self.marketrex_default_file_path(file_name)
    Rails.root.join('public', 'system', 'marketrex_uploads', "#{file_name}").to_s
  end

  def self.symbolize_keys h
    Hash[h.map { |k, v| [k.gsub(/\ /, "_").gsub("\n","_").downcase.to_sym, v] if !k.nil? }]
  end

  def self.symbolize_keys_and_values h
    Hash[h.map { |k, v|
      k = k.gsub(/\ /, "_")
        .gsub("\n","_")
        .downcase
        .to_sym if k.is_a? String
      v = v.gsub(/\ /, "_")
        .downcase
        .to_sym if v.is_a? String
      [ k, v ]
    }]
  end

  def self.symbolize str
    str.gsub(/\ /, "_").gsub("\n","_").downcase.to_sym
  end

  def self.process_excel_file(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings, not_for_sheet)
    missing_column_header = []
    import_mappings.each do |mapping|
      mapping = mapping.last
      missing_column_header << mapping[:record_column] if mapping[:spreadsheet_column].empty?
    end
    # missing Columns headers check

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
      p column_names
      errors = ""
      missing_not_required_columns = []
      removed_not_required_columns = []
      template          = ImportTemplate.unscoped.find(template_id)
      template_columns  = Hash[template.import_mappings.map { |x| [x.record_column, x.spreadsheet_column] }]
      formatted_columns = ImportTemplateUtil.symbolize_keys(column_names).keys.map { |x| x.to_s.strip }
      missing_columns   = ImportTemplateUtil.symbolize_keys(template_columns.values).keys.map { |x| x.to_s.strip } - formatted_columns

      # db columns - spreadsheet columns
      if !missing_columns.empty?
        missing_columns.each do |column|
          # Ignore anything with lease structure related
          next if template_columns.has_value? column and template_columns.key(column).match(/^leasestructure_.*$/)
          # errors += column.to_s.split('_').map(&:capitalize).join(' ') + "\n"
          if required?(TenantRecord, column.to_sym)
            errors += column.to_s.split('_').map(&:capitalize).join(' ') + "\n"
          else
            missing_not_required_columns << column.to_s unless column.empty?
          end
        end
      end

      # form submitted missing columns
      if !missing_column_header.empty?
        missing_column_header.each do |column|
          if required?(TenantRecord, column.to_sym)
            errors += column.to_s.split('_').map(&:capitalize).join(' ') + "\n"
          else
            removed_not_required_columns << column.to_s
          end
        end
      end


      if (missing_not_required_columns - removed_not_required_columns).length > 0
        (missing_not_required_columns - removed_not_required_columns).each do |column|
          errors += column.to_s.split('_').map(&:capitalize).join(' ') + "\n"
        end
      end


      unless errors.empty?
        raise Exception.new errors + "\nMake sure your file has all the above column headings. No trailing whitespace allowed."
      end

      row_offset = 1
      total = @sheet.last_row - row_offset
      if (total <= 0)
        import.update_attributes(:total_record_count => total)
        raise Exception.new("No records found.")
      end

      import.update_attributes(:status => "Validating records...", :total_record_count => total)
      @sheet.parse(:header_search => column_names[0..1], :clean => true).each_with_index do |row, i|
        if i > 0
          p row

          TenantRecordImport.increment_counter(:total_traversed_count, import_id)
          if not_for_sheet[:class] == "TenantRecord"
            not_for_sheet[:additional_tenant_cost] = 0.0
            not_for_sheet[:additional_ll_allowance] = 0.0
            lease_stepped_rents = []
            if !(not_for_sheet[:additional_cost].nil?)
              if !(not_for_sheet[:additional_cost][:tenant].nil?)
                not_for_sheet[:additional_cost][:tenant].each { |cost_column|
                  not_for_sheet[:additional_tenant_cost] += row[cost_column.last].to_f
                }
              end
              if !(not_for_sheet[:additional_cost][:ll].nil?)
                not_for_sheet[:additional_cost][:ll].each { |cost_column|
                  not_for_sheet[:additional_ll_allowance] += row[cost_column.last].to_f
                }
              end
            end
            Sidekiq::Logging.logger.debug "*****************************************************"
            Sidekiq::Logging.logger.debug not_for_sheet[:rent_escalation_type_stepped]
            if !(not_for_sheet[:stepped_rents].nil?)
              if (not_for_sheet[:rent_escalation_type_stepped] and not_for_sheet[:stepped_rents].count > 0 )
                counter = 0
                not_for_sheet[:stepped_rents].each { |step|
                  lease_stepped_rents[counter] = {'cost_per_month' => row[step.last[:cost_per_month]].to_f , 'months' => row[step.last[:months]].to_i}
                  counter += 1
                }
                not_for_sheet.merge!({
                                         'lease_stepped_rents' => lease_stepped_rents
                                     })
              end
            end
          end
          parsed_spreadsheet_record = Importer.hash_format(import_id, row)
          CustomImporter.validate(parsed_spreadsheet_record, import_id, current_user_info, not_for_sheet)
        end
      end

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

end
