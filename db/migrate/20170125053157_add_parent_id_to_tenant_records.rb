class AddParentIdToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :parent_id, :integer
  end
end
