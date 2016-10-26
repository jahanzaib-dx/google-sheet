class DropAgreementsTenantRecords < ActiveRecord::Migration
  def change
    drop_table :agreements_tenant_records
  end
end
