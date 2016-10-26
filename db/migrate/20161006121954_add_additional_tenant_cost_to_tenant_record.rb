class AddAdditionalTenantCostToTenantRecord < ActiveRecord::Migration
  def change
    add_column :tenant_records, :additional_tenant_cost, :decimal, { :precision => 20, :scale => 2, :default => 0 }
  end
end
