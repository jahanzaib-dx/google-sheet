class TenantRecordImport < ActiveRecord::Base

  belongs_to :user
  belongs_to :import_template
  belongs_to :lease_structure
  # belongs_to :team
  has_many :import_records, :dependent => :destroy
  has_many :tenant_record_import_operating_expense_mapping, :dependent => :destroy


  #attr_accessible :complete, :completed_at, :total_traversed_count, :total_record_count, :num_imported_records, :import_template_attributes, :lease_structure_attributes
  attr_accessor :error

  accepts_nested_attributes_for :import_records
  accepts_nested_attributes_for :import_template
  accepts_nested_attributes_for :lease_structure
  accepts_nested_attributes_for :tenant_record_import_operating_expense_mapping

  def start(uploaded_file, current_user_info, import_mappings_dup)
    self.status = "Verifying the spreadsheet format"
    begin
      ImportTenantRecordsWorker.perform_async(self.id, uploaded_file.path, uploaded_file.original_filename, import_template.id, current_user_info, import_mappings_dup)
    rescue NoMethodError => e
      self.update_attributes(:status => "Invalid file.\n")
      # self.status = "Invalid file.\n"
      self.error = true
      Rails.logger.debug [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
    rescue Exception => e
      # self.status = "File Could not be uploaded.\n"
      self.update_attributes(:status => "File Could not be uploaded.\n")
      self.error = true
      Rails.logger.debug [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
    end
    # import = TenantRecordImport.find(self.id)
    save
  end

  def marketrex_import_start(file_path, current_user_info, import_mappings_dup, original_file_name, not_for_sheet)
    self.status = "Verifying the spreadsheet format"
    begin

      #CustomImportTenantRecordsWorker.perform(self.id, file_path, original_file_name, import_template.id, current_user_info, import_mappings_dup, not_for_sheet)

      CustomImportTenantRecordsWorker.perform_async(self.id, file_path, original_file_name, import_template.id, current_user_info, import_mappings_dup, not_for_sheet)
    rescue NoMethodError => e
      self.update_attributes(:status => "Invalid file.\n")
      self.error = true
      # self.status = "Invalid file.\n"
      Rails.logger.debug [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
    rescue Exception => e
      # self.status = "File Could not be uploaded.\n"
      self.update_attributes(:status => "File Could not be uploaded.\n")
      self.error = true
      Rails.logger.debug [e.inspect, e.message, e.backtrace.join("\n")].join("\n")
    end
    # import = TenantRecordImport.find(self.id)
    save
  end

  def update_record(r)
    record = import_records.find(r[:id].to_i)
    record.data = r
    record.save
  end

  def custom_validate_record record = nil, current_user_info
    self.status = "Validating records..."
    if record
      record_id = record[:id].to_s
      class_name = YAML.load(record[:custom].gsub(/=>/, ': '))["class"] rescue ''
      jid = CustomValidateImportWorker.perform_async(id, record_id, current_user_info, class_name)
    else
      #validates everything
      jid = CustomValidateImportWorker.perform_async(id, nil, current_user_info, nil)
    end
    save
    jid
  end

  # validates all import records or only certeain ones if they are given
  #
  def validate_record record = nil, current_user_info
    self.status = "Validating records..."
    if record
      record_id = record[:id].to_s
      jid = ValidateImportWorker.perform_async(id, office.id, record_id, current_user_info)
    else
      #validates everything
      jid = ValidateImportWorker.perform_async(id, office.id, nil, current_user_info)
    end
    save
    jid
  end


  def update_flags


    self.import_valid = ImportRecord.where(:tenant_record_import_id => id, :record_valid => false).count == 0
    self.geocode_valid = ImportRecord.where(:tenant_record_import_id => id, :geocode_valid => false).count == 0

    if !import_valid || !geocode_valid
      self.status = 'Validating records...'
    end

    if (self.total_record_count == self.total_traversed_count && self.total_record_count > self.num_imported_records)
      self.status = 'Some comps need attention.'
      self.complete = true
    end


    if self.total_record_count == self.num_imported_records and self.total_record_count > 0
      self.complete = true
      self.completed_at = DateTime.now
      self.status = 'Import has completed'
    end

    if self.errors.any?
      self.complete = true
      self.status = self.errors[:upload].to_s
    end

    save
  end


end
