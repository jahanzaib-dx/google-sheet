class AddMasterIdToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :master_id, :integer
  end
end
