class DeleteOfficeTenantRecordsFromAgreementWorker
  include Sidekiq::Worker
  sidekiq_options queue: "agreements"

  def perform(agreement_id, office_id)
    agreement = Agreement.find(agreement_id)
    if ! agreement.nil?
      agreement.delete_office_tenant_records(office_id)
    end
  end

end
