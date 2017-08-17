#require 'sidekiq/testing/inline'
Sidekiq::Logging.logger.level = Logger::DEBUG

class CustomImportTenantRecordsWorker
  include Sidekiq::Worker
  include CustomImportTemplateUtil
  sidekiq_options :queue => :import, :retry => false

  def perform(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings_dup, not_for_sheet)

    Sidekiq.logger.debug "starting sidekiq perform..."
    Sidekiq.logger.debug "class: #{ not_for_sheet.inspect } "

    if not_for_sheet["class"].eql?('CustomRecord')
      CustomRecordUtil.process_bulk_upload(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings_dup, not_for_sheet)
    else
      CustomImportTemplateUtil.process_excel_file(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings_dup, not_for_sheet)
    end

  end

end