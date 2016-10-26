class AddAdditionalLlAllowanceToTenantRecord < ActiveRecord::Migration
  def change
    add_column :tenant_records, :additional_ll_allowance, :decimal, { :precision => 20, :scale => 2, :default => 0 }
  end
end
