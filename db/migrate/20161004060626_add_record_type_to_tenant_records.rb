class AddRecordTypeToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :record_type, :string, :default => 'lease'
    ##TenantRecord.update_all(:record_type => "lease")
  end
end
