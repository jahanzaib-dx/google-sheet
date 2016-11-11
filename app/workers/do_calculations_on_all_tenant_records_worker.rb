class DoCalculationsOnAllTenantRecordsWorker
  include Sidekiq::Worker
  sidekiq_options queue: "calculator"

  def perform(limit = 10000, offset = 0, office_id = 0, update_at=nil)

    limit     ||= 10000
    offset    ||= 0
    office_id ||= 0

    if (office_id == 0)
      tenant_records = TenantRecord.limit(limit).offset(offset)
    else
      tenant_records = TenantRecord.where(:office_id => office_id).limit(limit).offset(offset)
    end
    if (!update_at.nil?)
      tenant_records.where('updated_at > ?', updated_at)
    end
    tenant_records.each do |record|
      RunTenantEffectiveCalculatorWorker.perform_async(record.id)
    end
    if (tenant_records.count == limit)
      DoCalculationsOnAllTenantRecordsWorker.perform_async(limit.to_i, offset.to_i + limit.to_i + 1, office_id)
    end
  end

end
