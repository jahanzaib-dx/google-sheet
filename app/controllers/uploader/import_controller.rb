class Uploader::ImportController < ApplicationController
  #include CalculatorUtil
  #include CushmanCalculationEngine
  include GoogleGeocoder

  before_filter :authenticate_user!

  before_filter :save_temp_file, only: :process_file

  layout 'uploader'

  def index
    imports_for_user
  end

  def show
    @import = TenantRecordImport.find(params[:id])

    @records = @import.import_records.
        where("geocode_valid = ? or record_valid = ?", false, false).
        order(:id).
        paginate(:page => params[:page], :per_page => 5)

    import_errors
    render :notice => params[:notice]
  end

  def destroy
    begin
      record = TenantRecordImport.find params[:id]
      record.destroy if can? :manage, record
    rescue Exception => e
      puts "Error while deleting 'TenantRecordImport'"
    end

    redirect_to uploader_import_index_path
  end

  def import_status
    imports_for_user
    respond_to do |format|
      format.js
    end
  end

  def new
    @import = TenantRecordImport.new
    @import.lease_structure = LeaseStructure.new
    @import.import_template = ImportTemplate.new
    TenantRecord::REQUIRED_FIELDS.each_with_index do |required_field, i|
      @import.import_template.import_mappings << ImportMapping.new(:import_template => @template, :record_column => required_field)
    end
  end

  def update
    @import = TenantRecordImport.find(params[:id])
    @import.update_record(params[:tenant_record_import][:import_records_attributes][params[:record]])
    jid = @import.custom_validate_record(params[:tenant_record_import][:import_records_attributes][params[:record]], current_user_account_type)

    # job = SidekiqStatus::Container.load(jid)
    # while job.status != "complete"
    #   sleep 0.1
    #   job.reload
    # end

    @records = @import.import_records.where("geocode_valid = ? or record_valid = ?", false, false).order(:id).
        paginate(:page => params[:page], :per_page => 5)

    import_errors

    @update = true

    respond_to do |format|
      format.html { render :partial => "marketrex/import/show_form", :content_type => 'text/html' }
      format.json { render json: { section: params[:record] } }
    end
  end

  def create_and_process_upload
    file_path = CustomImportTemplateUtil.marketrex_default_file_path(params[:upload_file_tmp_url])
    original_file_name = params[:upload_file_tmp_url]
    #@sheet = Roo::Excelx.new("#{file_path}")

    ext = File.extname("#{file_path}")[1..-1]

    @sheet = Roo::Excel.new("#{file_path}") if( ext.match('xls') )
    @sheet = Roo::Excelx.new("#{file_path}") if( ext.match('xlsx'))

    required_params = {}
    not_for_sheet = {}
    if params[:bulk_property_type_switch] == 'sales_comps'
      not_for_sheet.merge!({
                               :is_sales_record => (params[:sale_record][:is_sales_record] == 'yes' ? true : false ),
                               :land_size_identifier => (params[:sale_record][:land_size_identifier] == 'acres' ? "Acres" : "Sf"),
                               :class => 'SaleRecord'
                           })
      params[:sale_record].except(:is_sales_record, :land_size_identifier).to_hash.each_with_index { |(key, value), index|
        required_params["#{index}"] = { id: "", record_column: key, spreadsheet_column: value, default_value: "" }
      }
    elsif params[:bulk_property_type_switch]  == 'custom_data'
      if params[:custom_record][:custom_record_properties_attributes]
        custom_record_properties = {}
        params[:custom_record][:custom_record_properties_attributes].each_with_index do |hash, index|
          custom_record_properties["#{index}"] = {
              key: hash[1][:key],
              value: hash[1][:value]
          }
        end
      end
      not_for_sheet.merge!({
                              :custom_record_properties => custom_record_properties,
                              :is_existing_data_set => (params[:custom_record][:is_existing_data_set] == 'yes' ? true : false ),
                              :is_geo_coded => (params[:custom_record][:is_geo_coded] == 'on' ? true : false),
                              :class => 'CustomRecord'
                          })
      params[:custom_record].except(:is_existing_data_set, :is_geo_coded, :custom_record_properties_attributes).to_hash.each_with_index { |(key, value), index|
        required_params["#{index}"] = { id: "", record_column: key, spreadsheet_column: value, default_value: "" }
      }
    elsif params[:bulk_property_type_switch]  == 'lease_comps'
      not_for_sheet.merge!({
                               :base_rent_type                 => params[:tenant_record][:base_rent_type],
                               :rent_escalation_type_percent   => (params[:tenant_record][:rent_escalation_type_percent].to_i == 1 ? true : false),
                               :rent_escalation_type_fixed     => (params[:tenant_record][:rent_escalation_type_fixed].to_i == 1 ? true : false),
                               :rent_escalation_type_stepped   => (params[:tenant_record][:rent_escalation_type_stepped].to_i == 1 ? true : false),
                               :free_rent_type_consecutive     => (params[:tenant_record][:free_rent_type_consecutive].to_i == 1 ? true : false),
                               :free_rent_type_non_consecutive => (params[:tenant_record][:free_rent_type_non_consecutive].to_i == 1 ? true : false),
                               :gross_free_rent                => (params[:tenant_record][:gross_free_rent].to_i == 1 ? true : false),
                               :is_tenant_improvement          => (params[:tenant_record][:is_tenant_improvement].to_i == 1 ? true : false),
                               :has_additional_tenant_cost     => (params[:tenant_record][:has_additional_tenant_cost] == 'on' ? true : false),
                               :additional_tenant_cost         => params[:tenant_record][:additional_tenant_cost],
                               :has_additional_ll_allowance    => (params[:tenant_record][:has_additional_ll_allowance] == 'on' ? true : false),
                               :additional_ll_allowance        => params[:tenant_record][:additional_ll_allowance],
                               :additional_cost                => params[:tenant_record][:additional_cost],
                               :stepped_rents                  => params[:tenant_record][:stepped_rents_attributes],
                               :class                          => 'TenantRecord'
                           })
      params[:tenant_record].except(:comp_data_type, :base_rent_type, :rent_escalation_type_percent, :rent_escalation_type_fixed, :rent_escalation_type_stepped, :free_rent_type_consecutive, :free_rent_type_non_consecutive, :gross_free_rent, :additional_tenant_cost, :additional_ll_allowance, :is_tenant_improvement, :has_additional_tenant_cost, :has_additional_ll_allowance, :additional_cost, :stepped_rents_attributes).to_hash.each_with_index { |(key, value), index|
        required_params["#{index}"] = { id: "", record_column: key, spreadsheet_column: value, default_value: "" }
      }
    end

    name = SecureRandom.hex
    import_template_attributes = { name: name, import_mappings_attributes: required_params }

    pre_existing = ImportTemplate.new(import_template_attributes.merge({
                                                             :name => name,
                                                             :reusable => false,
                                                             :office => current_user.account.office
                                                           }))

    mapping_structure = pre_existing.dup
    mapping_structure.name = [mapping_structure.name, Time.now.to_i.to_s].join(' ')
    import_mappings =  required_params #params[:tenant_record_import][:import_template_attributes][:import_mappings_attributes]

    import_mappings_dup = Marshal.load(Marshal.dump(import_mappings))
    CustomImportTemplateUtil.update_import_mappings mapping_structure, import_mappings
    import = TenantRecordImport.create(:office => current_user.account.office,
                                       #:team_id => current_user.account.own_team.id,
                                       :import_template => mapping_structure )

    import.marketrex_import_start(file_path, current_user_account_type, import_mappings_dup, original_file_name, not_for_sheet)
    #CustomImportTemplateUtil.create_template_spreadsheet(mapping_structure)

   render json: { text: "ok" }
    # respond_to do |format|
    #   format.js
    # end
  end

  def process_file

    if params[:fileToUpload]
      ext = File.extname(@file_path)[1..-1]

      spreadsheet = Roo::Excel.new(@file_path) if( ext.eql?('xls') )
      spreadsheet = Roo::Excelx.new(@file_path) if( ext.eql?('xlsx'))

      @headers = spreadsheet.first
    end

    respond_to do |format|
      format.js
    end
  end


  def filter_by_geocode
    @import = TenantRecordImport.find(params[:id])
    @import.update_flags

    import_errors

    @records = @import.import_records.where("geocode_valid = ? and defined(record_errors, 'geocode_info') and record_errors->'geocode_info' != '[]'", false).order(:id).
        paginate(:page => params[:page], :per_page => 5)

    render :action => :show, :notice => @import.errors[:upload].first
  end

  def filter_by_valid
    @import = TenantRecordImport.find(params[:id])
    @import.update_flags

    @records = @import.import_records.where("record_valid = ?", false).order(:id).
        paginate(:page => params[:page], :per_page => 5)

    import_errors

    render :action => :show, :notice => @import.errors[:upload].first
  end

  def undo
    begin
      import_logs = ImportLog.find_all_by_tenant_record_import_id params[:id]
      import_logs.each do |import_log|
        import_log.delete # Performance gain over destroy as callback won't be fired
        TenantRecord.destroy import_log.tenant_record_id # Callbacks needed so using destroy
      end
    rescue Exception => ex
    end
    TenantRecordImport.destroy params[:id] # Callbacks needed so using destroy
    imports_for_user
    # respond_to do |format|
    #   format.js
    # end
    redirect_to marketrex_import_index_path
  end

  private

  def save_temp_file
    if params[:fileToUpload]
      file = params[:fileToUpload].read
      @filename = params[:fileToUpload].original_filename
      random_string = SecureRandom.hex

      dir = File.join(Rails.root, 'public', 'system', 'marketrex_uploads')
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      @updated_file_name = random_string + @filename
      @file_path = File.join(dir, @updated_file_name)
      File.open(@file_path, 'wb') { |f| f.write file }
    end
  end

  def imports_for_user
    if current_user.has_trex_admin?
      @imports = TenantRecordImport
      @recent_imports_count = ImportLog.where(:created_at => 1.week.ago..Time.now).count
      @total_imports_count = ImportLog.count

    elsif current_user.has_firm_admin?
      offices = Firm.find(current_user.account.firm).offices.map{|o| o.id}
      @imports = TenantRecordImport.where(:office_id => offices)
      @recent_imports_count = ImportLog.where(:office_id => offices,
                                              :created_at => 1.week.ago..Time.now).count
      @firm_imports_count = ImportLog.where(:office_id => offices).count
    else
      office_id = current_user.account.office.id
      @imports = TenantRecordImport.where(:office_id => office_id)
      @recent_imports_count = ImportLog.where(:office_id => office_id,
                                              :created_at => 1.week.ago..Time.now).count
      @office_imports_count = ImportLog.where(:office_id => office_id).count

    end
    if @imports.respond_to?(:each)
      @imports.each do |tri|
        tri.update_flags if tri.status != 'Import has completed'
      end
    end
    @imports = @imports.order('created_at DESC').paginate(:page => params[:page], per_page: 10)
  end

  # call this function when bulk upload is done

  def clear_file_content path
    File.delete path
  end

  def import_errors
    @geocode_errors = @import.import_records.where("(geocode_valid = ? and defined(record_errors, 'geocode_info') and record_errors->'geocode_info' != '[]') and record_valid = ?", false, true).count
    @validation_errors = @import.import_records.where("record_valid = ?", false).count
  end
end