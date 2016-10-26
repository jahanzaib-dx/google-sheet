class AddFieldsToTenantRecords < ActiveRecord::Migration
  def change
    unless TenantRecord.column_names.include? 'has_additional_tenant_cost'
      add_column :tenant_records, :has_additional_tenant_cost, :boolean, default: false
    end
    unless TenantRecord.column_names.include? 'has_additional_ll_allowance'
      add_column :tenant_records, :has_additional_ll_allowance, :boolean, default: false
    end
  end
end
