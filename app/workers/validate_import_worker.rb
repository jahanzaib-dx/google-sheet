class ValidateImportWorker
  include SidekiqStatus::Worker
  sidekiq_options :queue => :validate_import, :retry => false

  def perform(import_id, office_id, id = nil, current_user_info)
    records = nil

    if id
      records = ImportRecord.where(:id => id)
    else
      records = ImportRecord.where(:tenant_record_import_id => import_id)
    end

    batch_size = 50
    records.find_in_batches(:batch_size => batch_size) do |batch|
      batch.each do |tmp_record|
        Importer.validate(tmp_record.data, import_id, tmp_record.id, current_user_info)
      end
    end
  end
end
