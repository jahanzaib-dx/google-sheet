class AddSalesColumnsToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :cap_rate, :float
    add_column :tenant_records, :sale_price, :float
    add_column :tenant_records, :build_date, :date
    add_column :tenant_records, :sold_date, :date
  end
end
