class AddGrossFreeRentToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :gross_free_rent, :boolean, default: false
  end
end
