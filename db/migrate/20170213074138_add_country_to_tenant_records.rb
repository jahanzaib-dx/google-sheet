class AddCountryToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :country, :string
  end
end
