#require 'sidekiq/testing/inline'

class CustomValidateImportWorker
  include SidekiqStatus::Worker
  sidekiq_options :queue => :validate_import, :retry => false

  def perform(import_id, id = nil, current_user_info, class_name)
    records = nil

    if id
      records = ImportRecord.where(:id => id)
    else
      records = ImportRecord.where(:tenant_record_import_id => import_id)
    end

    batch_size = 50
    records.find_in_batches(:batch_size => batch_size) do |batch|
      batch.each do |tmp_record|
        CustomImporter.validate(tmp_record.data, import_id, tmp_record.id, current_user_info, { "class" => class_name })
      end
    end
  end
end
