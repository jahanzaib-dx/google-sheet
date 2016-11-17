class RunTenantEffectiveCalculatorWorker
  include Sidekiq::Worker
  include CalculatorUtil
  include CushmanCalculationEngine
  sidekiq_options queue: "calculator"

  def perform(tenant_record_id)
    tenant_record = TenantRecord.find(tenant_record_id)
    begin
      results = calculate(tenant_record, 'TenantEffective')
      attributes = pull_attributes(results,tenant_record) rescue {}
      tenant_record.update_attributes(attributes)

    rescue Exception => e
      logger.debug "TenantRecordId: " + tenant_record_id.to_s
      logger.debug e.inspect + "\n" + e.message + "\n" + e.backtrace.join("\n")
    end
  end
end

