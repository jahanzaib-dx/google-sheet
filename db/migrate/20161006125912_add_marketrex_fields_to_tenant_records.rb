class AddMarketrexFieldsToTenantRecords < ActiveRecord::Migration
  def change
    add_column :tenant_records, :comp_view_type, :string
    add_column :tenant_records, :deal_type, :string
    add_column :tenant_records, :comp_data_type, :string
    add_column :tenant_records, :base_rent_type, :string
    add_column :tenant_records, :rent_escalation_type, :string
    add_column :tenant_records, :free_rent_type, :string
    add_column :tenant_records, :is_tenant_improvement, :boolean, default: false
    add_column :tenant_records, :fixed_escalation, :decimal, :precision => 20, :scale => 2, default: 0.0
  end
end
