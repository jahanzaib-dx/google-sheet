#require 'sidekiq/testing/inline'

class CustomImportTenantRecordsWorker
  include Sidekiq::Worker
  include CustomImportTemplateUtil
  sidekiq_options :queue => :import, :retry => false

  def perform(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings_dup, not_for_sheet)
    CustomImportTemplateUtil.process_excel_file(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings_dup, not_for_sheet)
  end

end