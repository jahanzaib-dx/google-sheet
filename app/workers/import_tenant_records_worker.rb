class ImportTenantRecordsWorker
  include Sidekiq::Worker
  include ImportTemplateUtil
  sidekiq_options :queue => :import, :retry => false

  def perform(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings_dup)
    ImportTemplateUtil.process_excel_file(import_id, tmp_file_path, original_filename, template_id, current_user_info, import_mappings_dup)
  end

end