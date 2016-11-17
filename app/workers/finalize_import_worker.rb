class FinalizeImportWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :geocode, :retry => false

  def perform(office_id, batch_ids)

    ImportRecord.where(:id => batch_ids).each do |tmp_record|

      TenantRecord.create( tmp_record.template_converted_data.merge( :office_id => office_id ))
      tmp_record.imported = true
      tmp_record.save

    end

  end
end
